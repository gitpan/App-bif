package Bif::Role::Sync::Repo;
use strict;
use warnings;
use DBIx::ThinSQL qw/qv/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_9';

my %import_functions = (
    NEW => {
        issue          => 'func_import_issue',
        issue_status   => 'func_import_issue_status',
        project        => 'func_import_project',
        project_status => 'func_import_project_status',
        repo           => 'func_new_repo',
        repo_location  => 'func_import_repo_location',
        task           => 'func_import_task',
        task_status    => 'func_import_task_status',
        update         => 'func_import_update',
    },
    UPDATE => {
        issue          => 'func_import_issue_update',
        issue_status   => 'func_import_issue_status_update',
        project        => 'func_import_project_update',
        project_status => 'func_import_project_status_update',
        repo           => 'func_import_repo_update',
        repo_location  => 'func_import_repo_location_update',
        task           => 'func_import_task_update',
        task_status    => 'func_import_task_status_update',
    },
    QUIT   => {},
    CANCEL => {},
);

sub real_import_repo {
    my $self = shift;
    my $db   = $self->db;

    my ( $TOTAL, $total ) = $self->read;

    if ( $TOTAL ne 'TOTAL' ) {
        $self->write('ExpectedCount');
        return 'ExpectedCount';
    }

    my $ucount;

    while ( $total-- > 0 ) {
        my ( $action, $type, $ref ) = $self->read;

        if ( !exists $import_functions{$action} ) {
            $self->write( 'BadMethod', $action );
            return 'BadMethod';
        }

        if ( $action eq 'QUIT' or $action eq 'CANCEL' ) {
            $self->write('QUIT');
            return 'UnexpectedQuit';
        }

        if ( !exists $import_functions{$action}->{$type} ) {
            $self->write('NotImplemented');
            return 'NotImplemented';
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
    }

    $self->write('RepoImported');
    my ($action) = $self->read;
    $db->do('ANALYZE');
    return 'RepoImported' if $action eq 'RepoExported';
    return $action;
}

sub real_sync_repo {
    my $self   = shift;
    my $id     = shift || die caller;
    my $prefix = shift;
    my $tmp    = shift || 'sync_' . sprintf( "%08x", rand(0xFFFFFFFF) );

    $prefix = '' unless defined $prefix;
    my $prefix2 = $prefix . '_';
    my $db      = $self->db;

    $db->do("CREATE TEMPORARY TABLE $tmp(id INTEGER, ucount INTEGER)")
      if ( $prefix eq '' );

    my @refs = $db->xarrays(
        select => [qw/rm.prefix rm.hash/],
        from   => 'repos_merkle rm',
        where =>
          [ 'rm.repo_id = ', qv($id), ' AND rm.prefix LIKE ', qv($prefix2) ],
    );

    my $here = { map { $_->[0] => $_->[1] } @refs };
    $self->write( 'MATCH', $prefix2, $here );
    my ( $action, $mprefix, $there ) = $self->read;

    return 'ProtocolError'
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
            inner_join  => 'repo_related_updates rru',
            on          => {
                'rru.update_id' => \'u.id',
                'rru.repo_id'   => $id,
            },
            where => \@where,
        );
    }

    if (@next) {
        foreach my $next ( sort @next ) {
            $self->real_sync_repo( $id, $next, $tmp );
        }
    }

    return unless $prefix eq '';

    my ($total) = $self->db->xarray(
        select => 'COALESCE(sum(t.ucount), 0)',
        from   => "$tmp t",
    );

    $self->write( 'TOTAL', $total );

    my $update_list = $db->xprepare(
        select => [
            'u.id',                  'u.uuid',
            'p.uuid AS parent_uuid', 'u.mtime',
            'u.mtimetz',             'u.author',
            'u.email',               'u.lang',
            'u.message',             'u.ucount',
        ],
        from       => "$tmp t",
        inner_join => 'updates u',
        on         => 'u.id = t.id',
        left_join  => 'updates p',
        on         => 'p.id = u.parent_id',
        order_by   => 'u.id ASC',
    );

    $update_list->execute;
    $self->send_updates($update_list) || return;

    my ($uuid) = $db->xarray(
        select => 't.uuid',
        from   => 'topics t',
        where  => { 't.id' => $id },
    );

    return $self->real_import_repo($uuid);
}

sub real_export_repo {
    my $self = shift;
    my $id   = shift;

    my ($total) = $self->db->xarray(
        select     => 'sum(u.ucount)',
        from       => 'repo_related_updates rru',
        inner_join => 'updates u',
        on         => 'u.id = rru.update_id',
        where      => { 'rru.repo_id' => $id },
    );

    $self->write( 'TOTAL', $total );

    my $sth = $self->db->xprepare(
        select => [
            'updates.id',                  'updates.uuid',
            'parents.uuid AS parent_uuid', 'updates.mtime',
            'updates.mtimetz',             'updates.author',
            'updates.email',               'updates.lang',
            'updates.message',             'updates.ucount',
        ],
        from       => 'repo_related_updates AS rru',
        inner_join => 'updates',
        on         => 'updates.id = rru.update_id',
        left_join  => 'updates AS parents',
        on         => 'parents.id = updates.parent_id',
        where      => { 'rru.repo_id' => $id },
        order_by   => 'updates.id ASC',
    );

    $sth->execute;
    $self->send_updates($sth) || return;

    $self->write( 'RepoExported', $total );
    my ($action) = $self->read;
    return 'RepoExported' if $action eq 'RepoImported';
    return $action;
}

1;
