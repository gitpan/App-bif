package App::bif::new::project;
use strict;
use warnings;
use Bif::Mo;
use IO::Prompt::Tiny qw/prompt/;
use DBIx::ThinSQL qw/ qv sq/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub dup {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    my $path      = $opts->{path};
    my $dup_pinfo = $self->get_project( $opts->{dup} );

    $opts->{title} ||= $dbw->xval(
        select => 'p.title',
        from   => 'projects p',
        where  => { 'p.id' => $dup_pinfo->{id} },
    );

    my $src = $dbw->xval(
        select    => 'p.fullpath',
        from      => 'projects p',
        left_join => 'hubs h',
        on        => 'h.id = p.hub_id',
        where     => { 'p.id' => $dup_pinfo->{id} },
    );

    $opts->{message} ||=
      $self->prompt_edit( txt => "[ dup: $src ]\n", opts => $self );

    $dbw->txn(
        sub {
            my $id = $dbw->nextval('topics');
            my $uid = $self->new_change( message => $opts->{message}, );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    kind      => 'project',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_project',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    parent_id => $opts->{parent_id},
                    name      => $opts->{path},
                    title     => $opts->{title},
                },
            );

            $dbw->xdo(
                update => 'projects',
                set    => { local => 1, },
                where  => { id => $id },
            );

            if ( $dup_pinfo->{hub_id} ) {
                $dbw->xdo(
                    insert_into => 'func_update_project',
                    values      => {
                        id        => $id,
                        change_id => $uid,
                        hub_id    => $dup_pinfo->{hub_id},
                    },
                );
            }

            my @status = $dbw->xhashrefs(
                select    => [ 'ps.status', 'ps.rank', 'p.id AS current_id' ],
                from      => 'project_status ps',
                left_join => 'projects p',
                on       => 'p.project_status_id = ps.id',
                where    => { 'ps.project_id' => $dup_pinfo->{id} },
                order_by => 'ps.rank',
            );

            my $status_id;
            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $status_id = $sid if $status->{current_id};
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'project_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_project_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                    }
                );
            }

            $dbw->xdo(
                insert_into => 'project_deltas',
                values      => {
                    change_id         => $uid,
                    project_id        => $id,
                    project_status_id => $status_id,
                },
            );

            @status = $dbw->xhashrefs(
                select => [ 'ist.status', 'ist.rank', 'ist.def' ],
                from   => 'issue_status ist',
                where    => { 'ist.project_id' => $dup_pinfo->{id} },
                order_by => 'ist.rank',
            );

            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'issue_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_issue_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                        def        => $status->{def},
                    }
                );
            }

            @status = $dbw->xhashrefs(
                select => [ 'ts.status', 'ts.rank', 'ts.def' ],
                from   => 'task_status ts',
                where    => { 'ts.project_id' => $dup_pinfo->{id} },
                order_by => 'ts.rank',
            );

            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'task_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_task_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                        def        => $status->{def},
                    }
                );
            }

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id     => $uid,
                    new           => 1,
                    action_format => "dup project (%s) $opts->{path} "
                      . "from (%s) $dup_pinfo->{path}",
                    action_topic_id_1 => $id,
                    action_topic_id_1 => $dup_pinfo->{id},
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    printf( "Project created: %s\n", $path );
    return $self->ok('NewProject');
}

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    $opts->{path} ||= prompt( 'Path:', '' )
      || return $self->err( 'ProjectPathRequired', 'project path is required' );

    my $path = $opts->{path};

    return $self->err( 'ProjectExists',
        'project already exists: ' . $opts->{path} )
      if eval {
        grep { !defined $_->{hub_name} } $self->get_project( $opts->{path} );
      };

    if ( $opts->{path} =~ m/\// ) {
        my @parts = split( '/', $path );
        $opts->{path} = pop @parts;

        my $parent_path = join( '/', @parts );

        my $parent_pinfo = eval { $self->get_project($parent_path) }
          || return $self->err( 'ParentProjectNotFound',
            'parent project not found: ' . $parent_path );
        $opts->{parent_id} = $parent_pinfo->{id};
    }

    my $where;
    if ( $opts->{status} ) {
        return $self->err( 'InvalidStatus',
            'unknown status: ' . $opts->{status} )
          unless $dbw->xarrayref(
            select => 'count(*)',
            from   => 'default_status',
            where  => {
                kind   => 'project',
                status => $opts->{status},
            }
          );
    }

    return dup($self) if $opts->{dup};

    $opts->{title} ||= prompt( 'Title:', '' )
      || return $self->err( 'ProjectNameRequired',
        'project title is required' );

    $opts->{message} ||= $self->prompt_edit( opts => $self );
    $opts->{lang} ||= 'en';

    $dbw->txn(
        sub {
            my $id = $dbw->nextval('topics');
            my $uid = $self->new_change( message => $opts->{message}, );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    kind      => 'project',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_project',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    parent_id => $opts->{parent_id},
                    name      => $opts->{path},
                    title     => $opts->{title},
                },
            );

            $dbw->xdo(
                update => 'projects',
                set    => {
                    local => 1,
                },
                where => { id => $id },
            );

            my @status = $dbw->xhashrefs(
                select   => [ qw/status rank/, ],
                from     => 'default_status',
                where    => { kind => 'project' },
                order_by => 'rank',
            );

            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'project_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_project_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                    }
                );
            }

            $dbw->xdo(
                insert_into => [
                    'project_deltas',
                    qw/change_id project_id project_status_id/,
                ],
                select     => [ qv($uid), qv($id), 'project_status.id', ],
                from       => 'default_status',
                inner_join => 'project_status',
                on         => {
                    project_id              => $id,
                    'default_status.status' => \'project_status.status',
                },
                where => do {

                    if ( $opts->{status} ) {
                        {
                            'default_status.kind'   => 'project',
                            'default_status.status' => $opts->{status},
                        };
                    }
                    else {
                        {
                            'default_status.kind' => 'project',
                            'default_status.def'  => 1,
                        };
                    }
                },
            );

            @status = $dbw->xhashrefs(
                select   => [ qw/status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'issue' },
                order_by => 'rank',
            );

            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'issue_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_issue_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                        def        => $status->{def},
                    }
                );
            }

            @status = $dbw->xhashrefs(
                select   => [ qw/status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'task' },
                order_by => 'rank',
            );

            foreach my $status (@status) {
                my $sid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        change_id => $uid,
                        id        => $sid,
                        kind      => 'task_status',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_task_status',
                    values      => {
                        change_id  => $uid,
                        id         => $sid,
                        project_id => $id,
                        status     => $status->{status},
                        rank       => $status->{rank},
                        def        => $status->{def},
                    }
                );
            }

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new project (%s) $opts->{path}",
                    action_topic_id_1 => $id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    printf( "Project created: %s\n", $path );
    return $self->ok('NewProject');
}

1;
__END__

=head1 NAME

=for bif-doc #create

bif-new-project - create a new project

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif new project [PATH] [TITLE] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-project> command creates a new project.


=head1 ARGUMENTS & OPTIONS

=over

=item PATH

An identifier for the project. Consists of the parent PATH (if any)
plus the the name of the project separated by a slash "/". Will be
prompted for if not provided.

=item TITLE

A short summary of what the project is about. Will be prompted for if
not provided.

=item --dup, -d SRC

Duplicate the new project title and status types (project-status,
issue-status, task-status) from SRC, where SRC is an existing project
path. The SRC title can be overriden by providing a TITLE as the second
argument as described above.

=item --message, -m MESSAGE

The project description.  An editor will be invoked to record a MESSAGE
if this option is not used.

=back


=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

