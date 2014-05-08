package Bif::Role::Sync::Project;
use strict;
use warnings;
use Coro;
use DBIx::ThinSQL qw/qv/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_20';

my %import_functions = (
    NEW => {
        issue          => 'func_import_issue',
        issue_status   => 'func_import_issue_status',
        project        => 'func_import_project',
        project_status => 'func_import_project_status',
        task           => 'func_import_task',
        task_status    => 'func_import_task_status',
        update         => 'func_import_update',
    },
    UPDATE => {
        issue          => 'func_import_issue_update',
        issue_status   => 'func_import_issue_status_update',
        project        => 'func_import_project_update',
        project_status => 'func_import_project_status_update',
        task           => 'func_import_task_update',
        task_status    => 'func_import_task_status_update',
    },
    QUIT   => {},
    CANCEL => {},
);

sub recv_project_updates {
    my $self = shift;
    my $uuid = shift;
    my $db   = $self->db;

    my ( $action, $total ) = $self->read;
    $total //= '*undef*';

    if ( $action ne 'TOTAL' or $total !~ m/^\d+$/ ) {
        return "expected TOTAL <int> (not $action $total)";
    }

    my $ucount;
    my $i   = $total;
    my $got = 0;

    $self->updates_recv("$got/$total");
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
        $self->updates_recv("$got/$total");
        $self->trigger_on_update;
    }

    $self->updates_recv( ( ' ' x length("$got/") ) . $total );
    $self->trigger_on_update;

    return $total;
}

sub real_import_project {
    my $self = shift;
    my $uuid = shift;

    my $result = $self->recv_project_updates;

    if ( $result =~ m/^\d+$/ ) {
        my ($id) = $self->db->xarray(
            select => 't.id',
            from   => 'topics t',
            where  => {
                't.uuid' => $uuid,
            },
        );

        $self->db->xdo(
            update => 'projects',
            set    => 'local = 1',
            where  => { id => $id },
        );

        $self->write( 'Recv', $result );
        return 'ProjectImported';
    }

    $self->write( 'ProtocolError', $result );
    return $result;
}

sub real_sync_project {
    my $self   = shift;
    my $id     = shift || die caller;
    my $prefix = shift;
    my $tmp    = shift || 'sync_' . sprintf( "%08x", rand(0xFFFFFFFF) );

    $prefix = '' unless defined $prefix;
    my $prefix2   = $prefix . '_';
    my $db        = $self->db;
    my $on_update = $self->on_update;

    $db->do("CREATE TEMPORARY TABLE $tmp(id INTEGER, ucount INTEGER)")
      if ( $prefix eq '' );

    $on_update->( 'matching: ' . $prefix2 ) if $on_update;

    my @refs = $db->xarrays(
        select => [qw/pm.prefix pm.hash/],
        from   => 'projects_merkle pm',
        where =>
          [ 'pm.project_id = ', qv($id), ' AND pm.prefix LIKE ', qv($prefix2) ],
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
            inner_join  => 'project_related_updates pru',
            on          => 'pru.update_id = u.id',
            inner_join  => 'projects_tree pt',
            on          => {
                'pt.child'  => \'pru.project_id',
                'pt.parent' => $id,
            },
            where => \@where,
        );
    }

    if (@next) {
        foreach my $next ( sort @next ) {
            $self->real_sync_project( $id, $next, $tmp );
        }
    }

    return unless $prefix eq '';

    my $send = async {
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
        return $self->send_updates( $update_list, $total );
    };

    my $r1 = $self->recv_project_updates;
    my $r2 = $send->join;

    if ( $r1 =~ m/^\d+$/ ) {
        $self->write( 'Recv', $r1 );
        my ( $recv, $count ) = $self->read;
        return 'ProjectSync' if $recv eq 'Recv' and $count == $r2;
        $log->debug("MEH: $count $r2");
        return $recv;
    }

    $self->write( 'ProtocolError', $r1 );
    return $r1;
}

sub real_export_project {
    my $self = shift;
    my $id   = shift;

    my ($total) = $self->db->xarray(
        select     => 'sum(u.ucount)',
        from       => 'project_related_updates pru',
        inner_join => 'updates u',
        on         => 'u.id = pru.update_id',
        where      => { 'pru.project_id' => $id },
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
        from       => 'project_related_updates AS pru',
        inner_join => 'updates',
        on         => 'updates.id = pru.update_id',
        left_join  => 'updates AS parents',
        on         => 'parents.id = updates.parent_id',
        where      => { 'pru.project_id' => $id },
        order_by   => 'updates.id ASC',
    );

    $sth->execute;
    $self->send_updates( $sth, $total );

    my ( $recv, $count ) = $self->read;
    return 'ProjectExported' if $recv eq 'Recv' and $count == $total;
    return $recv;
}

1;
