package Bif::Role::Sync::Repo;
use strict;
use warnings;
use Coro;
use DBIx::ThinSQL qw/qv/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_26';

my %import_functions = (
    NEW => {
        entity                => 'func_import_entity',
        entity_contact_method => 'func_import_entity_contact_method',
        identity              => 'func_import_identity',
        issue                 => 'func_import_issue',
        issue_status          => 'func_import_issue_status',
        project               => 'func_import_project',
        project_status        => 'func_import_project_status',
        hub                   => 'func_import_hub',
        hub_repo              => 'func_import_hub_repo',
        task                  => 'func_import_task',
        task_status           => 'func_import_task_status',
        update                => 'func_import_update',
    },
    UPDATE => {
        entity                => 'func_import_entity_delta',
        entity_contact_method => 'func_import_entity_contact_method_delta',
        identity              => 'func_import_identity_delta',
        issue                 => 'func_import_issue_delta',
        issue_status          => 'func_import_issue_status_delta',
        project               => 'func_import_project_delta',
        project_status        => 'func_import_project_status_delta',
        hub                   => 'func_import_hub_delta',
        hub_repo              => 'func_import_hub_repo_delta',
        task                  => 'func_import_task_delta',
        task_status           => 'func_import_task_status_delta',
    },
    QUIT   => {},
    CANCEL => {},
);

sub recv_hub_deltas {
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

        my $func = $import_functions{$action}->{$type};

        my $id;
        if ( $action eq 'NEW' and $type eq 'update' ) {
            $ucount = delete $ref->{ucount};

            ($id) = $db->xarray(
                select => 'u.id',
                from   => 'updates u',
                where  => { 'u.uuid' => $ref->{uuid} },
            );
        }

        $got++;
        $ucount--;
        $self->updates_recv( $self->updates_recv + 1 );

        # If we already have this update then skip the rest of the
        # deltas
        if ($id) {
            while ($ucount) {
                $self->read;
                $got++;
                $ucount--;
                $self->updates_recv( $self->updates_recv + 1 );
            }
        }
        else {

            # This should be a savepoint?
            my $res = $db->xdo(
                insert_into => $func,
                values      => $ref,
            );

            if ( 0 == $ucount ) {
                $db->xdo(
                    insert_into => 'func_merge_updates',
                    values      => { merge => 1 },
                );
            }
        }

        $self->trigger_on_update;
    }

    return $total;
}

sub real_import_hub {
    my $self   = shift;
    my $result = $self->recv_hub_deltas;
    if ( $result =~ m/^\d+$/ ) {
        $self->write( 'Recv', $result );
        return 'RepoImported';
    }
    $self->write( 'ProtocolError', $result );
    return $result;
}

sub real_sync_hub {
    my $self   = shift;
    my $id     = shift || die caller;
    my $prefix = shift;
    my $tmp    = $self->temp_table;

    $prefix = '' unless defined $prefix;
    my $prefix2   = $prefix . '_';
    my $db        = $self->db;
    my $on_update = $self->on_update;

    $on_update->( 'matching: ' . $prefix2 ) if $on_update;

    my @refs = $db->xarrays(
        select => [qw/rm.prefix rm.hash/],
        from   => 'hub_related_updates_merkle rm',
        where =>
          [ 'rm.hub_id = ', qv($id), ' AND rm.prefix LIKE ', qv($prefix2) ],
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
            push( @where, "u.prefix LIKE ", qv( $miss . '%' ) ),;
        }

        $self->db->xdo(
            insert_into => "$tmp(id,ucount)",
            select      => [ 'u.id', 'u.ucount' ],
            from        => 'updates u',
            inner_join  => 'hub_related_updates rru',
            on          => {
                'rru.update_id' => \'u.id',
                'rru.hub_id'    => $id,
            },
            where => \@where,
        );
    }

    if (@next) {
        foreach my $next ( sort @next ) {
            $self->real_sync_hub( $id, $next, $tmp );
        }
    }

    return unless $prefix eq '';
    return 'RepoSync';
}

sub real_transfer_hub_updates {
    my $self = shift;
    my $tmp  = $self->temp_table;

    my $send = async {
        my ($total) = $self->db->xarray(
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
                'u.ucount',
            ],
            from       => "$tmp tmp",
            inner_join => 'updates u',
            on         => 'u.id = tmp.id',
            inner_join => 'topics t',
            on         => 't.id = u.identity_id',
            left_join  => 'updates p',
            on         => 'p.id = u.parent_id',
            order_by   => 'u.id ASC',
        );

        $update_list->execute;
        return $self->send_updates( $update_list, $total );
    };

    my $r1 = $self->recv_hub_deltas;
    my $r2 = $send->join;

    $self->db->xdo( delete_from => $tmp );

    if ( $r1 =~ m/^\d+$/ ) {
        $self->write( 'Recv', $r1 );
        my ( $recv, $count ) = $self->read;
        return 'TransferHubUpdates' if $recv eq 'Recv' and $count == $r2;
        $log->debug("MEH: $count $r2");
        return $recv;
    }

    $self->write( 'ProtocolError', $r1 );
    return $r1;
}

sub real_export_hub {
    my $self = shift;
    my $id   = shift;

    my ($total) = $self->db->xarray(
        select     => 'sum(u.ucount)',
        from       => 'hub_related_updates rru',
        inner_join => 'updates u',
        on         => 'u.id = rru.update_id',
        where      => { 'rru.hub_id' => $id },
    );

    $self->updates_tosend( $self->updates_tosend + $total );
    $self->write( 'TOTAL', $total );

    my $sth = $self->db->xprepare(
        select => [
            'updates.id',                  'updates.uuid',
            'parents.uuid AS parent_uuid', 't.uuid AS identity_uuid',
            'updates.mtime',               'updates.mtimetz',
            'updates.author',              'updates.email',
            'updates.lang',                'updates.message',
            'updates.ucount',
        ],
        from       => 'hub_related_updates AS rru',
        inner_join => 'updates',
        on         => 'updates.id = rru.update_id',
        inner_join => 'topics t',
        on         => 't.id = updates.identity_id',
        left_join  => 'updates AS parents',
        on         => 'parents.id = updates.parent_id',
        where      => { 'rru.hub_id' => $id },
        order_by   => 'updates.id ASC',
    );

    $sth->execute;
    $self->send_updates( $sth, $total );

    my ( $recv, $count ) = $self->read;
    return 'RepoExported' if $recv eq 'Recv' and $count == $total;
    return $recv;
}

1;
