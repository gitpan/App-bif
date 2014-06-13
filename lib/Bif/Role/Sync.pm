package Bif::Role::Sync;
use strict;
use warnings;
use DBIx::ThinSQL qw/coalesce qv/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_24';

with qw/ Bif::Role::Sync::Repo Bif::Role::Sync::Project /;

sub read {
    my $self = shift;

    my $json = $self->rh->readline("\n\n");

    if ( !defined $json ) {
        $self->on_error->('connection close/timeout');
        $self->write('EOF/Timeout');
        return 'EOF';
    }

    $log->debugf( 'r: ' . $json );
    my $msg = eval { $self->json->decode($json) };

    if ( $@ or !defined $msg ) {
        $self->on_error->( $@ || 'no message received' );
        $self->write('InvalidEncoding');
        return 'INVALID';
    }

    return @$msg;
}

sub write {
    my $self = shift;

    $log->debugf(
        'w: %s', $log->is_debug
        ? $self->json->encode( \@_ )
        : \@_
    );

    return $self->wh->print( $self->json->encode( \@_ ) . "\n\n" );
}

sub trigger_on_update {
    my $self = shift;
    $self->on_update->( 'deltas sent: '
          . ( $self->updates_sent // '' )
          . ' received: '
          . ( $self->updates_recv // '' ) );
}

sub send_updates {
    my $self        = shift;
    my $update_list = shift;
    my $total       = shift;
    my $db          = $self->db;

    my $sent = 0;
    $self->updates_sent("$sent/$total");
    $self->trigger_on_update;

    while ( my $update = $update_list->hash ) {
        my $id = delete $update->{id};

        $self->write( 'NEW', 'update', $update );

        my $parts = $db->xprepare(

            # hubs
            select => [
                qv('hub')->as('kind'),
                'hub_deltas.new',
                'hubs.uuid',    # for update
                'null AS undef1',
                'hub_deltas.related_update_uuid',
                'u.uuid AS update_uuid',
                'p.uuid AS project_uuid',
                'hub_deltas.name',
                8,
                'hub_deltas.id AS update_order',
            ],
            from       => 'hub_deltas',
            inner_join => 'updates u',
            on         => 'u.id = hub_deltas.update_id',
            inner_join => 'topics AS hubs',
            on         => 'hubs.id = hub_deltas.hub_id',
            left_join  => 'topics AS p',
            on         => 'p.id = hub_deltas.project_id',
            where      => { 'hub_deltas.update_id' => $id },

            # hub_repos
            union_all_select => [
                qv('hub_repo')->as('kind'), 'hrd.new',
                'h.uuid',                   'hr2.uuid',
                'hrd.location',             'u.uuid AS update_uuid',
                6,                          7,
                8,                          'hrd.id AS update_order',
            ],
            from       => 'updates u',
            inner_join => 'hub_repo_deltas hrd',
            on         => 'hrd.update_id = u.id',
            inner_join => 'hub_repos hr',
            on         => 'hr.id = hrd.hub_repo_id',
            inner_join => 'topics hr2',
            on         => 'hr2.id = hrd.hub_repo_id',
            inner_join => 'topics h',
            on         => 'h.id = hr.hub_id',
            where      => { 'u.id' => $id },

            # projects
            union_all_select => [
                qv('project')->as('kind'),
                'project_deltas.new',
                'projects.uuid',    # for update
                'parents.uuid',
                'project_deltas.name',
                'project_deltas.title',
                'status.uuid',      # for update
                'project_deltas.hub_uuid',
                'u.uuid AS update_uuid',
                'project_deltas.id AS update_order',
            ],
            from       => 'project_deltas',
            inner_join => 'updates u',
            on         => 'u.id = project_deltas.update_id',
            inner_join => 'topics AS projects',
            on         => 'projects.id = project_deltas.project_id',
            left_join  => 'topics AS parents',
            on         => 'parents.id = project_deltas.parent_id',
            left_join  => 'topics AS status',
            on         => 'status.id = project_deltas.status_id',
            where      => { 'project_deltas.update_id' => $id },

            # project_status
            union_all_select => [
                qv('project_status')->as('kind'),
                'project_status_deltas.new',
                'projects.uuid',    # for new
                'topics.uuid',      # for update
                'project_status_deltas.status',
                qv(undef)->as('varchar_filler'),
                qv(undef)->as('varchar_filler2'),
                'project_status_deltas.rank',
                'updates.uuid AS update_uuid',
                'project_status_deltas.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'project_status_deltas',
            on         => 'project_status_deltas.update_id = updates.id',
            left_join  => 'project_status',
            on         => {
                'project_status.id' => \
                  'project_status_deltas.project_status_id'
            },
            inner_join => 'topics',    # project_status
            on         => {
                'topics.id' => \'project_status.id'
            },
            inner_join => 'topics AS projects',
            on         => 'projects.id = project_status.project_id',
            where      => { 'updates.id' => $id },

            # task_status
            union_all_select => [
                qv('task_status')->as('kind'),
                'task_status_deltas.new',
                'projects.uuid',       # for new
                'topics.uuid',         # for update
                'task_status_deltas.status',
                'task_status_deltas.def',
                qv(undef)->as('varchar_filler2'),
                'task_status_deltas.rank',
                'updates.uuid AS update_uuid',
                'task_status_deltas.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'task_status_deltas',
            on         => 'task_status_deltas.update_id = updates.id',
            left_join  => 'task_status',
            on         => {
                'task_status.id' => \'task_status_deltas.task_status_id'
            },
            inner_join => 'topics',    # task_status
            on         => {
                'topics.id' => \'task_status.id'
            },
            inner_join => 'topics AS projects',
            on         => 'projects.id = task_status.project_id',
            where      => { 'updates.id' => $id },

            # issue_status
            union_all_select => [
                qv('issue_status')->as('kind'),
                'issue_status_deltas.new',
                'projects.uuid',       # for new
                'topics.uuid',         # for update
                'issue_status_deltas.status',
                'issue_status_deltas.def',
                qv(undef)->as('varchar_filler2'),
                'issue_status_deltas.rank',
                'updates.uuid AS update_uuid',
                'issue_status_deltas.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'issue_status_deltas',
            on         => 'issue_status_deltas.update_id = updates.id',
            left_join  => 'issue_status',
            on         => {
                'issue_status.id' => \'issue_status_deltas.issue_status_id'
            },
            inner_join => 'topics',    # issue_status
            on         => {
                'topics.id' => \'issue_status.id'
            },
            inner_join => 'topics AS projects',
            on         => 'projects.id = issue_status.project_id',
            where      => { 'updates.id' => $id },

            # tasks
            union_all_select => [
                qv('task')->as('kind'),
                'task_deltas.new',
                'tasks.uuid',          # for new
                'status.uuid',         # for update
                'task_deltas.title',
                'updates.uuid AS update_uuid',
                6,
                7,
                8,
                'task_deltas.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'task_deltas',
            on         => 'task_deltas.update_id = updates.id',
            inner_join => 'topics AS tasks',
            on         => {
                'tasks.id' => \'task_deltas.task_id'
            },
            left_join => 'topics AS status',
            on        => {
                'status.id' => \'task_deltas.status_id'
            },
            where => { 'updates.id' => $id },

            # issues
            union_all_select => [
                qv('issue')->as('kind'),
                'issue_deltas.new',
                'issues.uuid',          # for new
                'issue_status.uuid',    # for update
                'issue_deltas.title',
                'projects.uuid',
                'updates.uuid AS update_uuid',
                7,
                8,
                'issue_deltas.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'issue_deltas',
            on         => 'issue_deltas.update_id = updates.id',
            inner_join => 'topics AS issues',
            on         => {
                'issues.id' => \'issue_deltas.issue_id'
            },
            left_join => 'topics AS issue_status',
            on        => {
                'issue_status.id' => \'issue_deltas.status_id'
            },
            left_join => 'topics AS projects',
            on        => {
                'projects.id' => \'issue_deltas.project_id'
            },
            where => { 'updates.id' => $id },

            # Order everything correctly
            order_by => 'update_order',
        );

        $parts->execute;
        return $sent unless $self->write_parts($parts);

        $sent += $update->{ucount};
        $self->updates_sent("$sent/$total");
        $self->trigger_on_update;
    }

    $self->updates_sent( ( ' ' x length("$sent/") ) . $total );
    $self->trigger_on_update;

    return $sent;
}

sub write_parts {
    my $self  = shift;
    my $parts = shift;

    while ( my $part = $parts->array ) {
        if ( $part->[0] eq 'hub' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW', 'hub',
                    {
                        update_uuid => $part->[5],
                        name        => $part->[7],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE', 'hub',
                    {
                        hub_uuid            => $part->[2],
                        related_update_uuid => $part->[4],
                        update_uuid         => $part->[5],
                        project_uuid        => $part->[6],
                        name                => $part->[7],
                    }

                );
            }
        }
        elsif ( $part->[0] eq 'hub_repo' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'hub_repo',
                    {
                        hub_uuid    => $part->[2],
                        location    => $part->[4],
                        update_uuid => $part->[5],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'hub_repo',
                    {
                        hub_repo_uuid => $part->[3],
                        location      => $part->[4],
                        update_uuid   => $part->[5],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'project' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'project',
                    {
                        parent_uuid => $part->[3],
                        name        => $part->[4],
                        title       => $part->[5],
                        update_uuid => $part->[8],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'project',
                    {
                        project_uuid => $part->[2],
                        parent_uuid  => $part->[3],
                        name         => $part->[4],
                        title        => $part->[5],
                        status_uuid  => $part->[6],
                        hub_uuid     => $part->[7],
                        update_uuid  => $part->[8],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'project_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'project_status',
                    {
                        project_uuid => $part->[2],
                        status       => $part->[4],
                        rank         => $part->[7],
                        update_uuid  => $part->[8],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'project_status',
                    {
                        project_status_uuid => $part->[3],
                        status              => $part->[4],
                        rank                => $part->[7],
                        update_uuid         => $part->[8],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'task_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'task_status',
                    {
                        project_uuid => $part->[2],
                        status       => $part->[4],
                        def          => $part->[5],
                        rank         => $part->[7],
                        update_uuid  => $part->[8],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'task_status',
                    {
                        task_status_uuid => $part->[3],
                        status           => $part->[4],
                        def              => $part->[5],
                        rank             => $part->[7],
                        update_uuid      => $part->[8],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'issue_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'issue_status',
                    {
                        project_uuid => $part->[2],
                        status       => $part->[4],
                        def          => $part->[5],
                        rank         => $part->[7],
                        update_uuid  => $part->[8],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'issue_status',
                    {
                        issue_status_uuid => $part->[3],
                        status            => $part->[4],
                        def               => $part->[5],
                        rank              => $part->[7],
                        update_uuid       => $part->[8],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'task' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW', 'task',
                    {
                        task_status_uuid => $part->[3],
                        title            => $part->[4],
                        update_uuid      => $part->[5],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE', 'task',
                    {
                        task_uuid        => $part->[2],
                        task_status_uuid => $part->[3],
                        title            => $part->[4],
                        update_uuid      => $part->[5],
                    }
                );
            }
        }
        elsif ( $part->[0] eq 'issue' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW', 'issue',
                    {
                        issue_status_uuid => $part->[3],
                        title             => $part->[4],
                        update_uuid       => $part->[6],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE', 'issue',
                    {
                        issue_uuid        => $part->[2],
                        issue_status_uuid => $part->[3],
                        title             => $part->[4],
                        project_uuid      => $part->[5],
                        update_uuid       => $part->[6],
                    }
                );
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
