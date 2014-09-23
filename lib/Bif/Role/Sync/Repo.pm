package Bif::Role::Sync::Repo;
use strict;
use warnings;
use DBIx::ThinSQL qw/qv sq/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_28';

my $hub_functions = {
    entity_contact_method_delta => 'func_import_entity_contact_method_delta',
    entity_contact_method       => 'func_import_entity_contact_method',
    entity_delta                => 'func_import_entity_delta',
    entity                      => 'func_import_entity',
    hub_delta                   => 'func_import_hub_delta',
    hub                         => 'func_import_hub',
    hub_repo_delta              => 'func_import_hub_repo_delta',
    hub_repo                    => 'func_import_hub_repo',
    identity_delta              => 'func_import_identity_delta',
    identity                    => 'func_import_identity',
    issue_delta                 => 'func_import_issue_delta',
    issue                       => 'func_import_issue',
    issue_status_delta          => 'func_import_issue_status_delta',
    issue_status                => 'func_import_issue_status',
    project_delta               => 'func_import_project_delta',
    project                     => 'func_import_project',
    project_status_delta        => 'func_import_project_status_delta',
    project_status              => 'func_import_project_status',
    task_delta                  => 'func_import_task_delta',
    task                        => 'func_import_task',
    task_status_delta           => 'func_import_task_status_delta',
    task_status                 => 'func_import_task_status',
    topic                       => 'func_import_topic',
    change_delta                => 'func_import_change_delta',
    change                      => 'func_import_change',
};

sub real_import_hub {
    my $self   = shift;
    my $result = $self->recv_changesets($hub_functions);
    return 'RepoImported' if $result eq 'RecvChangesets';
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

    my @refs = $db->xarrayrefs(
        select => [qw/rm.prefix rm.hash/],
        from   => 'hub_related_changes_merkle rm',
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
            push( @where, "c.uuid LIKE ", qv( $miss . '%' ) ),;
        }

        $self->db->xdo(
            insert_into => "$tmp(id,ucount)",
            select      => [ 'c.id', 'c.ucount' ],
            from        => 'changes c',
            inner_join  => 'hub_related_changes hrc',
            on          => {
                'hrc.change_id' => \'c.id',
                'hrc.hub_id'    => $id,
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

sub real_transfer_hub_changes {
    my $self = shift;

    my $tmp   = $self->temp_table;
    my $total = $self->db->xval(
        select => 'COUNT(t.id)',
        from   => "$tmp t",
    );

    my $r = $self->exchange_changesets(
        $total,
        [
            with => 'src',
            as   => sq(
                select   => 't.id AS id',
                from     => "$tmp t",
                order_by => 't.id ASC',
            ),
        ],
        $hub_functions,
    );

    return $r unless $r eq 'ExchangeChangesets';
    return 'TransferHubChanges';
}

sub real_export_hub {
    my $self = shift;
    my $id   = shift;

    my $total = $self->db->xval(
        select => 'COUNT(hru.change_id)',
        from   => 'hub_related_changes hru',
        where  => { 'hru.hub_id' => $id },
    );

    my $recv = $self->send_changesets(
        $total,
        [
            with => 'src',
            as   => sq(
                select   => 'hru.change_id AS id',
                from     => 'hub_related_changes hru',
                where    => { 'hru.hub_id' => $id },
                order_by => 'hru.change_id ASC',
            ),
        ]
    );

    return 'RepoExported' if $recv eq 'ChangesetsSent';
    return $recv;
}

1;
