package Bif::Role::Sync;
use strict;
use warnings;
use DBIx::ThinSQL qw/coalesce qv/;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_6';

with qw/ Bif::Role::Sync::Repo Bif::Role::Sync::Project /;

sub read {
    my $self = shift;

    my $json = $self->rh->readline("\n\n");

    if ( !defined $json ) {
        $self->on_error->('no message received');
        return 'NoMsg';
    }

    $log->debugf( 'r: ' . $json );
    my $msg = eval { $self->json->decode($json) };

    if ( $@ or !defined $msg ) {
        $self->on_error->( $@ || 'no message received' );
        return 'InvalidEncoding';
    }

    return @$msg;
}

sub write {
    my $self = shift;

    $log->debugf( 'w: %s', $self->json->encode( \@_ ) )
      if $self->debug;

    return $self->wh->print( $self->json->encode( \@_ ) . "\n\n" );
}

sub send_updates {
    my $self        = shift;
    my $update_list = shift;
    my $db          = $self->db;

    while ( my $update = $update_list->hash ) {
        my $id = delete $update->{id};
        $self->write( 'NEW', 'update', $update );

        my $parts = $db->xprepare(

            # repos
            select => [
                qv('repo')->as('kind'),
                'repo_updates.new',
                'repos.uuid',    # for update
                'rl.uuid AS default_location_uuid',
                'projects.uuid',
                'repo_updates.related_update_uuid',
                6,
                qv(undef)->as('int_filler'),
                'repo_updates.id AS update_order',
            ],
            from       => 'repo_updates',
            inner_join => 'topics AS repos',
            on         => 'repos.id = repo_updates.repo_id',
            left_join  => 'topics AS rl',
            on         => 'rl.id = repo_updates.default_location_id',
            left_join  => 'topics AS projects',
            on         => 'projects.id = repo_updates.project_id',
            where      => { 'repo_updates.update_id' => $id },

            # repo_locations
            union_all_select => [
                qv('repo_location')->as('kind'),
                'rlu.new', 'r.uuid', 'rl2.uuid', 'rlu.location', 5, 6, 7,
                'rlu.id AS update_order',
            ],
            from       => 'updates u',
            inner_join => 'repo_location_updates rlu',
            on         => 'rlu.update_id = u.id',
            inner_join => 'repo_locations rl',
            on         => 'rl.id = rlu.repo_location_id',
            inner_join => 'topics rl2',
            on         => 'rl2.id = rlu.repo_location_id',
            inner_join => 'topics r',
            on         => 'r.id = rl.repo_id',
            where      => { 'u.id' => $id },

            # projects
            union_all_select => [
                qv('project')->as('kind'),
                'project_updates.new',
                'projects.uuid',    # for update
                'parents.uuid',
                'project_updates.name',
                'project_updates.title',
                'status.uuid',      # for update
                'project_updates.repo_uuid',
                'project_updates.id AS update_order',
            ],
            from       => 'project_updates',
            inner_join => 'topics AS projects',
            on         => 'projects.id = project_updates.project_id',
            left_join  => 'topics AS parents',
            on         => 'parents.id = project_updates.parent_id',
            left_join  => 'topics AS status',
            on         => 'status.id = project_updates.status_id',
            where      => { 'project_updates.update_id' => $id },

            # project_status
            union_all_select => [
                qv('project_status')->as('kind'),
                'project_status_updates.new',
                'projects.uuid',    # for new
                'topics.uuid',      # for update
                'project_status_updates.status',
                qv(undef)->as('varchar_filler'),
                qv(undef)->as('varchar_filler2'),
                'project_status_updates.rank',
                'project_status_updates.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'project_status_updates',
            on         => 'project_status_updates.update_id = updates.id',
            left_join  => 'project_status',
            on         => {
                'project_status.id' => \
                  'project_status_updates.project_status_id'
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
                'task_status_updates.new',
                'projects.uuid',       # for new
                'topics.uuid',         # for update
                'task_status_updates.status',
                'task_status_updates.def',
                qv(undef)->as('varchar_filler2'),
                'task_status_updates.rank',
                'task_status_updates.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'task_status_updates',
            on         => 'task_status_updates.update_id = updates.id',
            left_join  => 'task_status',
            on         => {
                'task_status.id' => \'task_status_updates.task_status_id'
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
                'issue_status_updates.new',
                'projects.uuid',       # for new
                'topics.uuid',         # for update
                'issue_status_updates.status',
                'issue_status_updates.def',
                qv(undef)->as('varchar_filler2'),
                'issue_status_updates.rank',
                'issue_status_updates.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'issue_status_updates',
            on         => 'issue_status_updates.update_id = updates.id',
            left_join  => 'issue_status',
            on         => {
                'issue_status.id' => \'issue_status_updates.issue_status_id'
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
                'task_updates.new',
                'tasks.uuid',          # for new
                'status.uuid',         # for update
                'task_updates.title',
                qv(undef)->as('varchar_filler'),
                qv(undef)->as('varchar_filler2'),
                qv(undef)->as('int_filler'),
                'task_updates.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'task_updates',
            on         => 'task_updates.update_id = updates.id',
            inner_join => 'topics AS tasks',
            on         => {
                'tasks.id' => \'task_updates.task_id'
            },
            left_join => 'topics AS status',
            on        => {
                'status.id' => \'task_updates.status_id'
            },
            where => { 'updates.id' => $id },

            # issues
            union_all_select => [
                qv('issue')->as('kind'),
                'issue_updates.new',
                'issues.uuid',          # for new
                'issue_status.uuid',    # for update
                'issue_updates.title',
                'projects.uuid',
                qv(undef)->as('varchar_filler2'),
                qv(undef)->as('int_filler'),
                'issue_updates.id AS update_order',
            ],
            from       => 'updates',
            inner_join => 'issue_updates',
            on         => 'issue_updates.update_id = updates.id',
            inner_join => 'topics AS issues',
            on         => {
                'issues.id' => \'issue_updates.issue_id'
            },
            left_join => 'topics AS issue_status',
            on        => {
                'issue_status.id' => \'issue_updates.status_id'
            },
            left_join => 'topics AS projects',
            on        => {
                'projects.id' => \'issue_updates.project_id'
            },
            where => { 'updates.id' => $id },

            # Order everything correctly
            order_by => 'update_order',
        );

        $parts->execute;
        return unless $self->write_parts($parts);
    }

    return 1;
}

sub write_parts {
    my $self  = shift;
    my $parts = shift;

    while ( my $part = $parts->array ) {
        if ( $part->[0] eq 'repo' ) {
            if ( $part->[1] ) {
                $self->write( 'NEW', 'repo', {} );
            }
            else {
                $self->write(
                    'UPDATE', 'repo',
                    {
                        repo_uuid             => $part->[2],
                        default_location_uuid => $part->[3],
                        project_uuid          => $part->[4],
                        related_update_uuid   => $part->[5],
                    }

                );
            }
        }
        elsif ( $part->[0] eq 'repo_location' ) {
            if ( $part->[1] ) {
                $self->write(
                    'NEW',
                    'repo_location',
                    {
                        repo_uuid => $part->[2],
                        location  => $part->[4],
                    }
                );
            }
            else {
                $self->write(
                    'UPDATE',
                    'repo_location',
                    {
                        repo_location_uuid => $part->[3],
                        location           => $part->[4],
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
                        repo_uuid    => $part->[7],
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
