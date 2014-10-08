package Bif::Role::Sync::Identity;
use strict;
use warnings;
use Coro;
use DBIx::ThinSQL qw/qv sq/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.2';

my %import_functions = (
    CHANGESET => {},
    QUIT      => {},
    CANCEL    => {},
);

my $identity_functions = {
    entity_contact_method_delta => 'func_import_entity_contact_method_delta',
    entity_contact_method       => 'func_import_entity_contact_method',
    entity_delta                => 'func_import_entity_delta',
    entity                      => 'func_import_entity',
    identity_delta              => 'func_import_identity_delta',
    identity                    => 'func_import_identity',
    topic                       => 'func_import_topic',
    change_delta                => 'func_import_change_delta',
    change                      => 'func_import_change',
};

sub real_import_identity {
    my $self   = shift;
    my $result = $self->recv_changesets($identity_functions);
    return 'IdentityImported' if $result eq 'RecvChangesets';
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
        from   => 'self_related_changes_merkle rm',
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
            push( @where, "c.uuid LIKE ", qv( $miss . '%' ) ),;
        }

        $self->db->xdo(
            insert_into => "$tmp(id,ucount)",
            select      => [ 'c.id', 'c.ucount' ],
            from        => 'changes c',
            inner_join  => 'self_related_changes src',
            on          => {
                'src.change_id' => \'c.id',
                'src.self_id'   => $id,
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

sub real_transfer_identity_changes {
    my $self = shift;
    my $tmp  = $self->temp_table;

    my $send = async {
        select $App::bif::pager->fh if $App::bif::pager;

        my $total = $self->db->xval(
            select => 'COALESCE(sum(t.ucount), 0)',
            from   => "$tmp t",
        );

        $self->changes_tosend( $self->changes_tosend + $total );
        $self->write( 'TOTAL', $total );

        my $change_list = $self->db->xprepare(
            select => [
                'c.id',                  'c.uuid',
                'p.uuid AS parent_uuid', 't.uuid AS identity_uuid',
                'c.mtime',               'c.mtimetz',
                'c.author',              'c.email',
                'c.lang',                'c.message',
                'c.action',              'c.ucount',
            ],
            from       => "$tmp tmp",
            inner_join => 'changes c',
            on         => 'c.id = tmp.id',
            left_join  => 'topics t',

            # Don't fetch the identity_uuid for the first identity
            # change
            on        => 't.id = c.identity_id AND t.first_change_id != c.id',
            left_join => 'changes p',
            on        => 'p.id = c.parent_id',
            order_by  => 'c.id ASC',
        );

        $change_list->execute;
        return $self->send_identity_changes( $change_list, $total );
    };

    my $r1 = $self->recv_identity_deltas;
    my $r2 = $send->join;

    $self->db->xdo( delete_from => $tmp );

    if ( $r1 =~ m/^\d+$/ ) {
        $self->write( 'Recv', $r1 );
        my ( $recv, $count ) = $self->read;
        return 'TransferIdentityChanges' if $recv eq 'Recv' and $count == $r2;
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
        select => 'COUNT(eru.change_id)',
        from   => 'entity_related_changes eru',
        where  => { 'eru.entity_id' => $id },
    );

    my $recv = $self->send_changesets(
        $total,
        [
            with => 'src',
            as   => sq(
                select   => 'eru.change_id AS id',
                from     => 'entity_related_changes eru',
                where    => { 'eru.entity_id' => $id },
                order_by => 'eru.change_id ASC',
            ),
        ]
    );

    return 'IdentityExported' if $recv eq 'ChangesetsSent';
    return $recv;
}

1;

=head1 NAME

=for bif-doc #perl

Bif::Role::Sync::Identity - synchronisation role for identities

