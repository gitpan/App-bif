package Bif::Sync;
use strict;
use warnings;
use Bif::Mo qw/is required default/;
use DBIx::ThinSQL qw/coalesce qv/;
use Log::Any '$log';
use JSON;

our $VERSION = '0.1.0';

has db => (
    is       => 'ro',
    required => 1,
);

has json => ( is => 'rw', default => sub { JSON->new->utf8 } );

has rh => ( is => 'rw' );

has wh => ( is => 'rw' );

has on_error => ( is => 'ro', required => 1 );

sub read {
    my $self = shift;

    my $json = $self->rh->readline;

    #    $log->debugf( 'r: %s', $json );

    my $msg = eval { $self->json->decode($json) };

    if ( $@ or !defined $msg ) {
        $self->on_error->( $@ || 'no message received' );
        return;
    }

    $log->debugf( 'r: %s', $self->json->pretty->encode($msg) );
    return $msg;
}

sub write {
    my $self = shift;
    my $msg  = shift;

    #    $log->debugf( 'w: %s', $self->json->encode($msg) );
    $self->json->pretty;
    $log->debugf( 'w: %s', $self->json->encode($msg) );
    $self->json->pretty(0);

    return $self->wh->print( $self->json->encode($msg) . "\n" );
}

sub write_parts {
    my $self  = shift;
    my $parts = shift;

    while ( my $part = $parts->array ) {
        if ( $part->[0] eq 'project' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW',
                        'project',
                        {
                            parent_uuid => $part->[3],
                            name        => $part->[4],
                            title       => $part->[5],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE',
                        'project',
                        {
                            project_uuid => $part->[2],
                            parent_uuid  => $part->[3],
                            name         => $part->[4],
                            title        => $part->[5],
                            status_uuid  => $part->[6],
                        }
                    ]
                );
            }
        }
        elsif ( $part->[0] eq 'project_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW',
                        'project_status',
                        {
                            project_uuid => $part->[2],
                            status       => $part->[4],
                            rank         => $part->[7],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE',
                        'project_status',
                        {
                            project_status_uuid => $part->[3],
                            status              => $part->[4],
                            rank                => $part->[7],
                        }
                    ]
                );
            }
        }
        elsif ( $part->[0] eq 'task_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW',
                        'task_status',
                        {
                            project_uuid => $part->[2],
                            status       => $part->[4],
                            def          => $part->[5],
                            rank         => $part->[7],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE',
                        'task_status',
                        {
                            task_status_uuid => $part->[3],
                            status           => $part->[4],
                            def              => $part->[5],
                            rank             => $part->[7],
                        }
                    ]
                );
            }
        }
        elsif ( $part->[0] eq 'issue_status' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW',
                        'issue_status',
                        {
                            project_uuid => $part->[2],
                            status       => $part->[4],
                            def          => $part->[5],
                            rank         => $part->[7],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE',
                        'issue_status',
                        {
                            issue_status_uuid => $part->[3],
                            status            => $part->[4],
                            def               => $part->[5],
                            rank              => $part->[7],
                        }
                    ]
                );
            }
        }
        elsif ( $part->[0] eq 'task' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW', 'task',
                        {
                            task_status_uuid => $part->[3],
                            title            => $part->[4],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE', 'task',
                        {
                            task_uuid        => $part->[2],
                            task_status_uuid => $part->[3],
                            title            => $part->[4],
                        }
                    ]
                );
            }
        }
        elsif ( $part->[0] eq 'issue' ) {
            if ( $part->[1] ) {
                $self->write(
                    [
                        'NEW', 'issue',
                        {
                            issue_status_uuid => $part->[3],
                            title             => $part->[4],
                        }
                    ]
                );
            }
            else {
                $self->write(
                    [
                        'UPDATE', 'issue',
                        {
                            issue_uuid        => $part->[2],
                            issue_status_uuid => $part->[3],
                            title             => $part->[4],
                            project_uuid      => $part->[5],
                        }
                    ]
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

sub generate_and_send {
    my $self        = shift;
    my $update_list = shift;
    my $db          = $self->db;

    while ( my $update = $update_list->hash ) {
        my $id = delete $update->{id};
        $self->write( [ 'NEW', 'update', $update ] );

        my $parts = $db->xprepare(

            # projects
            select => [
                qv('project')->as('kind'),
                'project_updates.new',
                'projects.uuid',    # for update
                'parents.uuid',
                'project_updates.name',
                'project_updates.title',
                'status.uuid',      # for update
                qv(undef)->as('int_filler'),
                'project_updates.update_order AS update_order',
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
                'project_status_updates.update_order AS update_order',
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
                'task_status_updates.update_order AS update_order',
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
                'issue_status_updates.update_order AS update_order',
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
                'task_updates.update_order AS update_order',
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
                'issue_updates.update_order AS update_order',
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

sub real_export_project {
    my $self  = shift;
    my $pinfo = shift;
    my $db    = $self->db;

    return $db->txn(
        sub {
            # TODO add to the hub_projects table here already?

            my $update_list = $db->xprepare(
                select => [
                    'updates.id',                  'updates.uuid',
                    'parents.uuid AS parent_uuid', 'updates.mtime',
                    'updates.mtimetz',             'updates.author',
                    'updates.email',               'updates.lang',
                    'updates.message',
                ],
                from       => 'project_related_updates AS pru',
                inner_join => 'updates',
                on         => 'updates.id = pru.update_id',
                left_join  => 'updates AS parents',
                on         => 'parents.id = updates.parent_id',
                where      => { 'pru.project_id' => $pinfo->{id} },
                order_by   => 'updates.id ASC',
            );

            $update_list->execute;
            $self->generate_and_send($update_list) || return;

            $self->write( [ 'MERGE', 'updates', { merge => 1 } ] );
            my $msg = $self->read;
            if ( !defined $msg || $msg->[0] != 201 ) {
                $db->rollback;
            }

            return $msg;
        }
    );
}

sub export_project {
    my $self  = shift;
    my $pinfo = shift;

    $self->write(
        [ $VERSION, 'EXPORT', 'project', $pinfo->{uuid}, $pinfo->{path} ] );

    my $msg = $self->read || return;
    return $msg unless $msg->[0] eq '100';

    return $self->real_export_project($pinfo);
}

my %import_functions = (
    NEW => {
        update         => 'func_import_update',
        project        => 'func_import_project',
        project_status => 'func_import_project_status',
        task_status    => 'func_import_task_status',
        issue_status   => 'func_import_issue_status',
        task           => 'func_import_task',
        issue          => 'func_import_issue',
    },
    UPDATE => {
        project        => 'func_import_project_update',
        project_status => 'func_import_project_status_update',
        task_status    => 'func_import_task_status_update',
        issue_status   => 'func_import_issue_status_update',
        task           => 'func_import_task_update',
        issue          => 'func_import_issue_update',
    },
    MERGE => {
        updates => 'func_merge_updates',
    },
    QUIT   => {},
    CANCEL => {},
);

sub import_project {
    my $self = shift;
    my $msg  = shift;
    my ( $uuid, $path ) = ( $msg->[3], $msg->[4] );

    my $local = $self->db->xhash(
        select    => [ 'projects.id AS id', 't2.uuid AS other_uuid', ],
        from      => '(select 1,2)',
        left_join => 'topics',
        on        => { 'topics.uuid' => $uuid },
        left_join => 'projects',
        on        => 'projects.id = topics.id',
        left_join => 'projects AS p2',
        on        => { 'p2.path'     => $path },
        left_join => 'topics AS t2',
        on        => 't2.id = p2.id',
        limit     => 1,
    );

    if ( $local->{id} ) {
        return $self->write( [ 308, 'Found', 'SYNC', 'project', $uuid ] );
    }
    elsif ( $local->{other_uuid} ) {
        $self->write( [ 409, 'Path Exists', $local->{other_uuid} ] );
        return;
    }

    $self->write( [ 100, 'Continue' ] );

    my $db = $self->db;    # save on method calls

    return $db->txn(
        sub {
            while ( my $msg = $self->read ) {
                if ( !exists $import_functions{ $msg->[0] } ) {
                    $self->write( [ 400, 'Bad DB Method: ' . $msg->[0] ] );
                    $db->rollback;
                    return;
                }

                if ( $msg->[0] eq 'QUIT' or $msg->[0] eq 'CANCEL' ) {
                    $self->write( [ 999, 'Rollback' ] );
                    $db->rollback;
                    return;
                }

                if ( !exists $import_functions{ $msg->[0] }->{ $msg->[1] } ) {
                    $self->write(
                        [ 501, "Not Implemented: $msg->[0] $msg->[1]" ] );
                    $db->rollback;
                    return;
                }

                my $func = $import_functions{ $msg->[0] }->{ $msg->[1] };

                # This should be a savepoint?
                $db->xdo(
                    insert_into => $func,
                    values      => $msg->[2],
                );

                if ( $msg->[0] eq 'MERGE' ) {
                    $log->infof( '201 EXPORT project %s', $uuid );
                    return $self->write( [ 201, 'Created' ] );
                }

            }

            $self->write( [ 999, 'Timeout/disconnect?' ] );
            $log->info('client disconnected');
            return;
        }
    );
}

1;
