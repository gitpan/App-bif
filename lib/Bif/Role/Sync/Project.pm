package Bif::Role::Sync::Project;
use strict;
use warnings;
use Log::Any '$log';
use Role::Basic;

our $VERSION = '0.1.0';

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

    # replace this by an update count and decide when to do
    # the merge locally
    MERGE => {
        updates => 'func_merge_updates',
    },
    QUIT   => {},
    CANCEL => {},
);

sub real_import_project {
    my $self = shift;
    my $uuid = shift;
    my $db   = $self->db;

    my $count = 0;
    return $db->txn(
        sub {
            while ( my $msg = $self->read ) {
                if ( !exists $import_functions{ $msg->[0] } ) {
                    $self->write(
                        [ 'BadMethod', 'Bad DB Method: ' . $msg->[0] ] );
                    $db->rollback;
                    return 'BadMethod';
                }

                if ( $msg->[0] eq 'QUIT' or $msg->[0] eq 'CANCEL' ) {
                    $self->write( [ 'QUIT', 'bye' ] );
                    $db->rollback;
                    return 'UnexpectedQuit';
                }

                if ( !exists $import_functions{ $msg->[0] }->{ $msg->[1] } ) {
                    $self->write(
                        [
                            'NotImplemented',
                            "Not Implemented: $msg->[0] $msg->[1]"
                        ]
                    );
                    $db->rollback;
                    return 'NotImplemented';
                }

                my $func = $import_functions{ $msg->[0] }->{ $msg->[1] };

                if ( $msg->[0] eq 'MERGE' ) {
                    my ($id) = $db->xarray(
                        select => 't.id',
                        from   => 'topics t',
                        where  => {
                            't.uuid' => $uuid,
                        },
                    );

                    $db->xdo(
                        update => 'projects',
                        set    => 'local = 1',
                        where  => { id => $id },
                    );

                    $db->xdo(
                        insert_into =>
                          [ 'repo_related_updates', qw/repo_id update_id/ ],
                        select => [ 'r.id', 'pru.update_id' ],
                        from       => 'project_related_updates pru',
                        inner_join => 'repos r',
                        on         => 'r.local = 1',
                        where      => { 'pru.project_id' => $id },
                    );
                }

                # This should be a savepoint?
                $db->xdo(
                    insert_into => $func,
                    values      => $msg->[2],
                );

                if ( $msg->[0] eq 'MERGE' ) {
                    if ( !$count ) {
                        $self->write( ['NoUpdates'] );
                        return 'NoUpdates';
                    }

                    $db->xdo(
                        insert_into =>
                          [ 'repo_related_updates', qw/repo_id update_id/ ],
                        select => [ 'r.id', 'pru.update_id' ],
                        from   => 'topics t',
                        inner_join => 'project_related_updates pru',
                        on         => 'pru.project_id = t.id',
                        inner_join => 'repos r',
                        on         => 'r.local = 1',
                        where      => {
                            't.uuid' => $uuid,
                        },
                    );

                    $self->write( ['ProjectImported'] );
                    $db->do('ANALYZE');
                    return 'ProjectImported';
                }

                $count++;
            }

            $self->write( ['Timeout'] );
            return 'Timeout';
        }
    );
}

sub real_sync_project {
    my $self = shift;
    my $id   = shift;
    my $db   = $self->db;

    return $db->txn(
        sub {

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
                where      => { 'pru.project_id' => $id },
                order_by   => 'updates.id ASC',
            );

            $update_list->execute;
            $self->send_updates($update_list) || return;

            $self->write( [ 'MERGE', 'updates', { merge => 1 } ] );
            return $self->read;
        }
    );
}

sub real_export_project {
    my $self = shift;
    my $id   = shift;
    my $db   = $self->db;

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
                where      => { 'pru.project_id' => $id },
                order_by   => 'updates.id ASC',
            );

            $update_list->execute;
            $self->send_updates($update_list) || return;

            $self->write( [ 'MERGE', 'updates', { merge => 1 } ] );
            my $msg = $self->read;
            return 'ProjectExported' if $msg->[0] eq 'ProjectImported';
            return $msg->[0];
        }
    );
}

=cut

sub compare_get_all {
    my $self    = shift;
    my $compare = shift;
    my $here    = shift;

    $self->push_read(
        sub {
            my ( $header, $there ) = $self->getmsg(@_);
            return unless $header;

            if ( $header->{_} ne 'map' ) {
                my $str = 'expected map';
                return $self->error( $str, $str );
            }
            elsif ( !exists $header->{prefix} ) {
                my $str = 'missing prefix';
                return $self->error( $str, $str );
            }
            elsif ( $compare ne $header->{prefix} ) {
                my $str = sprintf( 'wrong prefix. want %s have %s',
                    $compare, $header->{prefix} );
                return $self->error( $str, $str );
            }
            $self->expecting( $self->expecting - 1 );
            $self->comparing($compare);

            my @next;
            my @missing;

            my $temp_table = $self->db->irow( $self->temp_table );
            my ( $updates, $project_topics, $projects_tree ) =
              $self->db->srows(qw/updates project_topics projects_tree /);

            my $where;

            while ( my ( $k, $v ) = each %$here ) {
                if ( !exists $there->{$k} ) {
                    push( @missing, $k );
                }
                elsif ( $there->{$k} ne $v ) {
                    push( @next, $k );

                    #                    $next{$k} = [ @$compare, $k ];
                }
            }

            if (@missing) {
                my $where;
                foreach my $miss (@missing) {

             #                    my $prefix = join('', @$compare, $miss) . '%';
                    $where =
                        $where
                      ? $where . OR . $updates->prefix->like( $miss . '%' )
                      : $updates->prefix->like( $miss . '%' );
                }
                $self->db->do(
                    insert_into => $temp_table->('id'),
                    select      => [ $updates->update_id ],
                    from        => $updates,
                    inner_join  => $project_topics,
                    on => $project_topics->thread_id == $updates->thread_id,
                    inner_join => $projects_tree,
                    on =>
                      ( $projects_tree->child == $project_topics->project_id )
                      . AND
                      . ( $projects_tree->parent == $self->id ),
                    where => $where,
                );
            }

            $log->debugf( 'next %s and expecting %d', \@next,
                $self->expecting );
            return $self->run unless @next or $self->expecting;

            foreach my $k ( sort @next ) {
                $self->compare($k);
            }
        }
    );
}

sub compare_get {
    my $self    = shift;
    my $compare = shift;
    my $here    = shift;

    $self->push_read(
        sub {
            my ( $header, $there ) = $self->getmsg(@_);
            return unless $header;

            if ( $header->{_} ne 'map' ) {
                my $str = 'expected map';
                return $self->error( $str, $str );
            }
            elsif ( !exists $header->{prefix} ) {
                my $str = 'missing prefix';
                return $self->error( $str, $str );
            }
            elsif ( $compare ne $header->{prefix} ) {
                my $str = sprintf( 'wrong prefix. want %s have %s',
                    $compare, $header->{prefix} );
                return $self->error( $str, $str );
            }
            $self->expecting( $self->expecting - 1 );
            $self->comparing($compare);

            my @next;
            my @missing;

            my $temp_table = $self->db->irow( $self->temp_table );
            my ( $updates, $project_topics, $projects_tree ) =
              $self->db->srows(qw/updates project_topics projects_tree /);

            my $where;

            while ( my ( $k, $v ) = each %$here ) {
                if ( !exists $there->{$k} ) {
                    push( @missing, $k );
                }
                elsif ( $there->{$k} ne $v ) {
                    push( @next, $k );

                    #                    $next{$k} = [ @$compare, $k ];
                }
            }

            if (@missing) {
                my $where;
                foreach my $miss (@missing) {
                    $log->debug("ADDING MISS $miss");

             #                    my $prefix = join('', @$compare, $miss) . '%';
                    $where =
                      ( !defined $where )
                      ? $updates->prefix->like( $miss . '%' )
                      : $where . OR . $updates->prefix->like( $miss . '%' );
                }
                $self->db->do(
                    insert_into => $temp_table->('id'),
                    select      => [ $updates->update_id ],
                    from        => $updates,
                    inner_join  => $project_topics,
                    on => $project_topics->thread_id == $updates->thread_id,
                    inner_join => $projects_tree,
                    on =>
                      ( $projects_tree->child == $project_topics->project_id )
                      . AND
                      . ( $projects_tree->parent == $self->id ),
                    where => $where,
                );
            }

            $log->debugf( 'next %s and expecting %d', \@next,
                $self->expecting );
            return $self->run unless @next or $self->expecting;

            foreach my $k ( sort @next ) {
                $self->compare($k);
            }
        }
    );
}
=cut

1;
