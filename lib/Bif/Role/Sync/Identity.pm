package Bif::Role::Sync::Identity;
use strict;
use warnings;
use Coro;
use DBIx::ThinSQL qw/qv sq/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_27';

my %import_functions = (
    NEW => {
        topic                 => 'func_import_topic',
        entity                => 'func_import_entity',
        entity_contact_method => 'func_import_entity_contact_method',
        identity              => 'func_import_identity',
        update                => 'func_import_update',
    },
    UPDATE => {
        entity                => 'func_import_entity_delta',
        entity_contact_method => 'func_import_entity_contact_method_delta',
        identity              => 'func_import_identity_delta',
        update                => 'func_import_update_delta',
    },
    QUIT   => {},
    CANCEL => {},
);

sub recv_identity_deltas {
    my $self = shift;
    my $db   = $self->db;

    my ( $action, $total ) = $self->read;
    $total //= '*undef*';

    if ( $action ne 'TOTAL' or $total !~ m/^\d+$/ ) {
        return "expected TOTAL <int> (not $action $total)";
    }

    my $ucount;
    my $i   = $total;
    my $got = 0;

    $self->updates_torecv( $self->updates_torecv + $total );
    $self->trigger_on_update;

    while ( $got < $total ) {
        my ( $action, $type, $ref ) = $self->read;

        if ( !exists $import_functions{$action} ) {
            return "not implemented: $action";
        }

        if ( !exists $import_functions{$action}->{$type} ) {
            return "not implemented: $action $type";
        }

        if ( $action eq 'NEW' and $type eq 'update' ) {
            $ucount = delete $ref->{ucount};
        }

        my $func = $import_functions{$action}->{$type};

        # This should be a savepoint?
        $db->xdo(
            insert_into => $func,
            values      => $ref,
        );

        $ucount--;
        if ( 0 == $ucount ) {
            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }

        $got++;
        $self->updates_recv( $self->updates_recv + 1 );
        $self->trigger_on_update;

    }

    return $total;
}

sub real_import_identity {
    my $self   = shift;
    my $result = $self->recv_identity_deltas;
    if ( $result =~ m/^\d+$/ ) {
        $self->write( 'Recv', $result );
        return 'IdentityImported';
    }
    $self->write( 'ProtocolError', $result );
    return $result;
}

sub real_sync_identity {
    my $self   = shift;
    my $id     = shift || die caller;
    my $prefix = shift;
    my $tmp    = $self->temp_table;

    $prefix = '' unless defined $prefix;
    my $prefix2   = $prefix . '_';
    my $db        = $self->db;
    my $on_update = $self->on_update;

    $on_update->( 'matching: ' . $prefix2 ) if $on_update;

    my @refs = $db->xarrayrefs(
        select => [qw/rm.prefix rm.hash/],
        from   => 'self_related_updates_merkle rm',
        where =>
          [ 'rm.self_id = ', qv($id), ' AND rm.prefix LIKE ', qv($prefix2) ],
    );

    my $here = { map { $_->[0] => $_->[1] } @refs };
    $self->write( 'MATCH', $prefix2, $here );
    my ( $action, $mprefix, $there ) = $self->read;

    return "expected MATCH $prefix2 {} (not $action $mprefix ...)"
      unless $action eq 'MATCH'
      and $mprefix eq $prefix2
      and ref $there eq 'HASH';

    my @next;
    my @missing;

    while ( my ( $k, $v ) = each %$here ) {
        if ( !exists $there->{$k} ) {
            push( @missing, $k );
        }
        elsif ( $there->{$k} ne $v ) {
            push( @next, $k );
        }
    }

    if (@missing) {
        my @where;
        foreach my $miss (@missing) {
            push( @where, ' OR ' ) if @where;
            push( @where, "u.uuid LIKE ", qv( $miss . '%' ) ),;
        }

        $self->db->xdo(
            insert_into => "$tmp(id,ucount)",
            select      => [ 'u.id', 'u.ucount' ],
            from        => 'updates u',
            inner_join  => 'self_related_updates rru',
            on          => {
                'rru.update_id' => \'u.id',
                'rru.self_id'   => $id,
            },
            where => \@where,
        );
    }

    if (@next) {
        foreach my $next ( sort @next ) {
            $self->real_sync_identity( $id, $next, $tmp );
        }
    }

    return unless $prefix eq '';
    return 'IdentitySync';
}

sub real_transfer_identity_updates {
    my $self = shift;
    my $tmp  = $self->temp_table;

    my $send = async {
        my $total = $self->db->xval(
            select => 'COALESCE(sum(t.ucount), 0)',
            from   => "$tmp t",
        );

        $self->updates_tosend( $self->updates_tosend + $total );
        $self->write( 'TOTAL', $total );

        my $update_list = $self->db->xprepare(
            select => [
                'u.id',                  'u.uuid',
                'p.uuid AS parent_uuid', 't.uuid AS identity_uuid',
                'u.mtime',               'u.mtimetz',
                'u.author',              'u.email',
                'u.lang',                'u.message',
                'u.action',              'u.ucount',
            ],
            from       => "$tmp tmp",
            inner_join => 'updates u',
            on         => 'u.id = tmp.id',
            left_join  => 'topics t',

            # Don't fetch the identity_uuid for the first identity
            # update
            on        => 't.id = u.identity_id AND t.first_update_id != u.id',
            left_join => 'updates p',
            on        => 'p.id = u.parent_id',
            order_by  => 'u.id ASC',
        );

        $update_list->execute;
        return $self->send_identity_updates( $update_list, $total );
    };

    my $r1 = $self->recv_identity_deltas;
    my $r2 = $send->join;

    $self->db->xdo( delete_from => $tmp );

    if ( $r1 =~ m/^\d+$/ ) {
        $self->write( 'Recv', $r1 );
        my ( $recv, $count ) = $self->read;
        return 'TransferIdentityUpdates' if $recv eq 'Recv' and $count == $r2;
        $log->debug("MEH: $count $r2");
        return $recv;
    }

    $self->write( 'ProtocolError', $r1 );
    return $r1;
}

sub real_export_identity {
    my $self = shift;
    my $id   = shift;

    my $total = $self->db->xval(
        select     => 'sum(u.ucount)',
        from       => 'entity_related_updates eru',
        inner_join => 'updates u',
        on         => 'u.id = eru.update_id',
        where      => { 'eru.entity_id' => $id },
    );

    $self->updates_tosend( $self->updates_tosend + $total );
    $self->write( 'TOTAL', $total );

    my $sth = $self->db->xprepare(
        select => [
            'u.id',                  'u.uuid',
            'p.uuid AS parent_uuid', 't.uuid AS identity_uuid',
            'u.mtime',               'u.mtimetz',
            'u.author',              'u.email',
            'u.lang',                'u.message',
            'u.action',              'u.ucount',
        ],
        from       => 'entity_related_updates eru',
        inner_join => 'updates u',
        on         => 'u.id = eru.update_id',
        left_join  => 'topics t',

        # Don't fetch the identity_uuid for the first identity
        # update
        on        => 't.id = u.identity_id AND t.first_update_id != u.id',
        left_join => 'updates AS p',
        on        => 'p.id = u.parent_id',
        where     => { 'eru.entity_id' => $id },
        order_by  => 'u.id ASC',
    );

    $sth->execute;
    $self->send_identity_updates( $sth, $total );

    my ( $recv, $count ) = $self->read;
    return 'IdentityExported' if $recv eq 'Recv' and $count == $total;
    return $recv;
}

sub send_identity_updates {
    my $self        = shift;
    my $update_list = shift;
    my $total       = shift;
    my $db          = $self->db;

    my $sent = 0;

    while ( my $update = $update_list->hashref ) {
        my $id = delete $update->{id};

        $self->write( 'NEW', 'update', $update );

        my $parts = $db->xprepare(

            # topics
            select => [
                qv('topic'),         # 0
                1,                   # 1  AS NEW
                't.kind',            # 2
                'u.uuid',            # 3
                4,                   # 4
                5,                   # 5
                6,                   # 6
                't.update_order',    # 7
                8,                   # 8
            ],
            from       => 'updates u',
            inner_join => 'topics t',
            on         => 't.first_update_id = u.id',
            where      => { 'u.id' => $id },

            # entities
            union_all_select => [
                qv('entity')->as('kind'),                    # 0
                'ed.new',                                    # 1
                'ed.name',                                   # 2
                'u.uuid AS update_uuid',                     # 3
                't2.uuid AS contact_uuid',                   # 4
                't3.uuid AS default_contact_method_uuid',    # 5
                't.uuid AS entity_uuid',                     # 6
                'ed.id AS update_order',                     # 7
                8,                                           # 8
            ],
            from       => 'entity_deltas ed',
            inner_join => 'updates u',
            on         => 'u.id = ed.update_id',
            inner_join => 'topics t',
            on         => 't.id = ed.entity_id',
            left_join  => 'topics t2',
            on         => 't2.id = ed.contact_id',
            left_join  => 'topics t3',
            on         => 't3.id = ed.default_contact_method_id',
            where      => { 'ed.update_id' => $id },

            # entity_contact_methods
            union_all_select => [
                qv('entity_contact_method')->as('kind'),    # 0
                'ecmd.new',                                 # 1
                'ecmd.method',                              # 2
                'ecmd.mvalue',                              # 3
                'u.uuid AS update_uuid',                    # 4
                't.uuid AS entity_contact_method_uuid',     # 5
                't2.uuid AS entity_uuid',                   # 6
                'ecmd.id AS update_order',                  # 7
                8,                                          # 8
            ],
            from       => 'entity_contact_method_deltas ecmd',
            inner_join => 'updates u',
            on         => 'u.id = ecmd.update_id',
            inner_join => 'entity_contact_methods ecm',
            on         => 'ecm.id = ecmd.entity_contact_method_id',
            inner_join => 'topics t',
            on         => 't.id = ecm.id',
            inner_join => 'topics t2',
            on         => 't2.id = ecm.entity_id',
            where      => { 'ecmd.update_id' => $id },

            # identities
            union_all_select => [
                qv('identity')->as('kind'),    # 0
                'id.new',                      # 1
                'u.uuid AS update_uuid',       # 2
                't.uuid AS identity_uuid',     # 3
                4,                             # 4
                5,                             # 5
                6,                             # 6
                'id.id AS update_order',       # 7
                8,                             # 8
            ],
            from       => 'identity_deltas id',
            inner_join => 'updates u',
            on         => 'u.id = id.update_id',
            inner_join => 'topics t',
            on         => 't.id = id.identity_id',
            where      => { 'id.update_id' => $id },

            # update_deltas
            union_all_select => [
                qv('update')->as('kind'),
                'ud.new', 't1.uuid', 't2.uuid', 'ud.action_format', 5, 6,
                'ud.id AS update_order', 8,
            ],
            from       => 'updates u',
            inner_join => 'update_deltas ud',
            on         => 'ud.update_id = u.id',
            left_join  => 'topics t1',
            on         => 't1.id = ud.action_topic_id_1',
            left_join  => 'topics t2',
            on         => 't2.id = ud.action_topic_id_2',
            where      => { 'u.id' => $id },

            # Order everything correctly
            order_by => 'update_order',
        );

        $parts->execute;
        return $sent unless $self->write_identity_parts($parts);

        $sent += $update->{ucount};
        $self->updates_sent( $self->updates_sent + $update->{ucount} );
        $self->trigger_on_update;
    }

    return $sent;
}

sub write_identity_parts {
    my $self  = shift;
    my $parts = shift;

    while ( my $part = $parts->arrayref ) {
        if ( $part->[0] eq 'topic' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    $part->[0],
                    {
                        update_uuid => $part->[3],
                        kind        => $part->[2],
                    }
                );
            }
            else {
            }
        }
        elsif ( $part->[0] eq 'entity' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    $part->[0],
                    {
                        update_uuid => $part->[3],
                        topic_uuid  => $part->[6],
                        name        => $part->[2],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    $part->[0],
                    {
                        entity_uuid                 => $part->[6],
                        name                        => $part->[2],
                        update_uuid                 => $part->[3],
                        contact_uuid                => $part->[4],
                        default_contact_method_uuid => $part->[5],
                    }

                );
            }
        }
        elsif ( $part->[0] eq 'entity_contact_method' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    $part->[0],
                    {
                        method      => $part->[2],
                        mvalue      => $part->[3],
                        update_uuid => $part->[4],
                        topic_uuid  => $part->[5],
                        entity_uuid => $part->[6],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    $part->[0],
                    {
                        method                     => $part->[2],
                        mvalue                     => $part->[3],
                        update_uuid                => $part->[4],
                        entity_contact_method_uuid => $part->[5],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'identity' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    $part->[0],
                    {
                        update_uuid => $part->[2],
                        entity_uuid => $part->[3],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    $part->[0],
                    {
                        update_uuid   => $part->[2],
                        identity_uuid => $part->[3],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'update' ) {
            if ( $part->[1] ) {
                $self->write(
                    'UPDATE', 'update',
                    {
                        action_topic_uuid_1 => $part->[2],
                        action_topic_uuid_2 => $part->[3],
                        action_format       => $part->[4],
                    }
                );
            }
            else {
                $self->on_error->( 'cannot export type: ' . $part->[0] );
                return;
            }
        }
        else {
            $self->on_error->( 'cannot export type: ' . $part->[0] );
            return;
        }
    }
    return 1;
}

1;
