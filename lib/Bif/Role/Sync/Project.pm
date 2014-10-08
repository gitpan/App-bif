package Bif::Role::Sync::Project;
use strict;
use warnings;
use DBIx::ThinSQL qw/qv sq/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.2';

my $project_functions = {
    entity_contact_method_delta => 'func_import_entity_contact_method_delta',
    entity_contact_method       => 'func_import_entity_contact_method',
    entity_delta                => 'func_import_entity_delta',
    entity                      => 'func_import_entity',
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

sub real_import_project {
    my $self   = shift;
    my $result = $self->recv_changesets($project_functions);
    return 'ProjectImported' if $result eq 'RecvChangesets';
    return $result;
}

sub real_sync_project {
    my $self   = shift;
    my $id     = shift || die caller;
    my $ids    = shift || die caller;
    my $prefix = shift // '';

    my @ids       = grep { $_ != $id } @$ids;
    my $tmp       = $self->temp_table;
    my $prefix2   = $prefix . '_';
    my $db        = $self->db;
    my $on_update = $self->on_update;
    my $hub_id    = $self->hub_id;

    $on_update->( 'matching: ' . $prefix2 ) if $on_update;

    my @refs = $db->xarrayrefs(
        select => [qw/pm.prefix pm.hash/],
        from   => 'project_related_changes_merkle pm',
        where  => [
            'pm.project_id = ',     qv($id),
            ' AND pm.hub_id = ',    qv($hub_id),
            ' AND pm.prefix LIKE ', qv($prefix2)
        ],
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
            inner_join  => 'project_related_changes pru',
            on          => {
                'pru.change_id'           => \'c.id',
                'pru.project_id'          => $id,
                'NOT pru.real_project_id' => \@ids,
            },
            inner_join => 'projects_tree pt',
            on         => {
                'pt.child'  => \'pru.project_id',
                'pt.parent' => $id,
            },
            where => \@where,
        );
    }

    if (@next) {
        foreach my $next ( sort @next ) {
            $self->real_sync_project( $id, $ids, $next, $tmp );
        }
    }

    return unless $prefix eq '';

    return 'ProjectSync';
}

sub real_transfer_project_related_changes {
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
        $project_functions,
    );

    $self->db->xdo( delete_from => $tmp );

    return $r unless $r eq 'ExchangeChangesets';
    return 'TransferProjectRelatedChanges';
}

sub real_export_project {
    my $self = shift;
    my $id   = shift;

    my $total = $self->db->xval(
        select => 'COUNT(oru.change_id)',
        from   => 'project_related_changes pru',
        where  => { 'pru.project_id' => $id },
    );

    my $recv = $self->send_changesets(
        $total,
        [
            with => 'src',
            as   => sq(
                select   => 'pru.change_id AS id',
                from     => 'project_related_changes pru',
                where    => { 'pru.project_id' => $id },
                order_by => 'pru.change_id ASC',
            ),
        ]
    );

    return 'ProjectExported' if $recv eq 'ChangesetsSent';
    return $recv;
}

1;

=head1 NAME

=for bif-doc #perl

Bif::Role::Sync::Project - synchronisation role for projects

