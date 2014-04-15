package Bif::Role::Sync::Repo;
use strict;
use warnings;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0_7';

sub real_export_repo {
    my $self = shift;
    my $id = shift || die 'repo_export_repo(ID)';

    my $sth = $self->db->xprepare(
        select => [
            'updates.id',                  'updates.uuid',
            'parents.uuid AS parent_uuid', 'updates.mtime',
            'updates.mtimetz',             'updates.author',
            'updates.email',               'updates.lang',
            'updates.message',
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

    $self->write( 'MERGE', 'updates', { merge => 1 } );
    return $self->read;
}

my %import_func = (
    NEW => {
        update         => 'func_import_update',
        repo           => 'func_new_repo',
        repo_location  => 'func_import_repo_location',
        project        => 'func_import_project',
        project_status => 'func_import_project_status',
        task_status    => 'func_import_task_status',
        issue_status   => 'func_import_issue_status',
        task           => 'func_import_task',
        issue          => 'func_import_issue',
    },
    UPDATE => {
        repo           => 'func_import_repo_update',
        repo_location  => 'func_import_repo_location_update',
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

sub real_import_repo {
    my $self = shift;
    my $db   = $self->db;    # save on method calls

    my $count = 0;
    return $db->txn(
        sub {
            while ( my ( $action, $type, $ref ) = $self->read ) {
                if ( !exists $import_func{$action} ) {
                    $self->write('BadMethod');
                    $db->rollback;
                    return 'BadMethod';
                }

                if ( $action eq 'QUIT' or $action eq 'CANCEL' ) {
                    $self->write( 'QUIT', 'bye' );
                    $db->rollback;
                    return 'UnexpectedQuit';
                }

                my $func = $import_func{$action}->{$type};
                if ( !$func ) {
                    $self->write('NotImplemented');
                    $db->rollback;
                    return 'NotImplemented';
                }

                # This should be a savepoint?
                $db->xdo(
                    insert_into => $func,
                    values      => $ref,
                );

                if ( $action eq 'MERGE' ) {
                    if ( !$count ) {
                        $self->write('NoUpdates');
                        return 'NoUpdates';
                    }
                    $self->write('RepoImported');
                    $db->do('ANALYZE');
                    return 'RepoImported';
                }

                $count++;
            }

            $self->write('Timeout');
            return 'Timeout';
        }
    );
}

sub real_sync_repo {
    my $self = shift;
    my $id   = shift;
    my $db   = $self->db;

    return $db->txn(
        sub {
            my $here = $db->xhash(
                select => ['hash'],
                from   => 'repos',
                where  => { id => $id },
            );

            $self->write( 'HASH', $here->{hash} );

            my $there = $self->read;

            if ( !$there ) {
                die "unhandled read error";
            }
            elsif ( $there->[0] ne 'HASH' ) {
                die "unexpected response: " . $there->[0];
            }
            elsif ( !defined $here->{hash} and defined $there->[1] ) {
                return $self->real_import_project;
            }
            elsif ( defined $here->{hash} and !defined $there->[1] ) {
                return $self->real_export_repo($id);
            }
            elsif ( $there->[1] eq $here->{hash} ) {
                return ['SYNCOK'];
            }

            while ( my $msg = $self->read ) {
                if ( !exists $import_func{ $msg->[0] } ) {
                    $self->write( 400, 'Bad DB Method: ' . $msg->[0] );
                    $db->rollback;
                    return;
                }

                if ( $msg->[0] eq 'QUIT' or $msg->[0] eq 'CANCEL' ) {
                    $self->write( 999, 'Rollback' );
                    $db->rollback;
                    return;
                }

                if ( !exists $import_func{ $msg->[0] }->{ $msg->[1] } ) {
                    $self->write( 501, "Not Implemented: $msg->[0] $msg->[1]" );
                    $db->rollback;
                    return;
                }

                my $func = $import_func{ $msg->[0] }->{ $msg->[1] };

                # This should be a savepoint?
                $db->xdo(
                    insert_into => $func,
                    values      => $msg->[2],
                );

                if ( $msg->[0] eq 'MERGE' ) {
                    $log->infof('201 EXPORT project');
                    $db->do('ANALYZE');
                    return $self->write( 201, 'Created' );
                }

            }

            $self->write( 999, 'Timeout/disconnect?' );
            $log->info('client disconnected');
            return;
        }
    );
}

1;
