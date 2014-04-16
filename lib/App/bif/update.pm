package App::bif::update;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_9';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    my $info =
         $db->get_topic( $ctx->{id} )
      || $ctx->get_project( $ctx->{id} )
      || return $ctx->err( 'TopicNotFound', 'topic not found: ' . $ctx->{id} );

    $info->{update_id} = $info->{first_update_id};

    my $func = __PACKAGE__->can( '_update_' . $info->{kind} )
      || return $ctx->err(
        'Update' . ucfirst( $info->{kind} ) . 'Unimplemented',
        "cannnot update topics of type \"$info->{kind}\""
      );

    $ctx->{lang} ||= 'en';

    # TODO calculate parent_update_id

    return $func->( $ctx, $db, $info );
}

sub _update_project {
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;

    my ( $status_ids, $invalid );
    if ( $ctx->{status} ) {

        ( $status_ids, $invalid ) =
          $db->status_ids( $info->{id}, 'project', $ctx->{status} );

        return $ctx->err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );
    $ctx->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $ctx->{update_id},
                    parent_id => $info->{update_id},
                    author    => $ctx->{user}->{name},
                    email     => $ctx->{user}->{email},
                    message   => $ctx->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $info->{id},
                    update_id => $ctx->{update_id},
                    $ctx->{title} ? ( title     => $ctx->{title} )    : (),
                    $status_ids   ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $db->update_repo(
                {
                    author            => $ctx->{user}->{name},
                    email             => $ctx->{user}->{email},
                    related_update_id => $ctx->{update_id},
                    message           => 'update project '
                      . "$info->{id} [$ctx->{id}]"
                      . ( $ctx->{status} ? ("[$ctx->{status}]") : '' ),
                }
            );
        }
    );

    print "Project updated: $ctx->{id}.$ctx->{update_id}\n";

    # For testing
    $ctx->{id}     = $info->{id};
    $ctx->{status} = $status_ids;
    return $ctx->ok('UpdateProject');
}

sub _update_issue {
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;

    my ($project_id) = $db->xarray(
        select => 'project_issues.project_id',
        from   => 'project_issues',
        where  => { 'project_issues.id' => $info->{id} },
    );

    my ( $status_ids, $invalid ) =
      $db->status_ids( $info->{project_id}, 'issue', $ctx->{status} );

    return $ctx->err( 'InvalidStatus',
        'unknown status(s): ' . join( ', ', @$invalid ) )
      if @$invalid;

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );
    $ctx->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $ctx->{update_id},
                    parent_id => $info->{update_id},
                    author    => $ctx->{user}->{name},
                    email     => $ctx->{user}->{email},
                    message   => $ctx->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id         => $info->{id},
                    update_id  => $ctx->{update_id},
                    project_id => $info->{project_id},
                    $ctx->{title} ? ( title     => $ctx->{title} )    : (),
                    @$status_ids  ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            my ($path) = $db->xarray(
                select => 'p.path',
                from   => 'projects p',
                where  => { 'p.id' => $info->{project_id} },
            );

            $db->update_repo(
                {
                    author            => $ctx->{user}->{name},
                    email             => $ctx->{user}->{email},
                    related_update_id => $ctx->{update_id},
                    message           => 'update issue '
                      . $info->{project_issue_id}
                      . " [$path]"
                      . ( $ctx->{status} ? ("[$ctx->{status}]") : '' ),
                }
            );
        }
    );

    print "Issue updated: $info->{project_issue_id}.$ctx->{update_id}\n";

    # For testing
    $ctx->{id}               = $info->{id};
    $ctx->{parent_update_id} = $info->{update_id};
    $ctx->{status}           = $status_ids;
    return $ctx->ok('UpdateIssue');
}

sub _update_task {
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;

    my ( $status_ids, $invalid );
    if ( $ctx->{status} ) {
        my ($project_id) = $db->xarray(
            select     => 'task_status.project_id',
            from       => 'tasks',
            inner_join => 'task_status',
            on         => 'task_status.id = tasks.status_id',
            where      => { 'tasks.id' => $info->{id} },
        );

        ( $status_ids, $invalid ) =
          $db->status_ids( $project_id, 'task', $ctx->{status} );

        return $ctx->err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );
    $ctx->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $ctx->{update_id},
                    parent_id => $info->{update_id},
                    author    => $ctx->{user}->{name},
                    email     => $ctx->{user}->{email},
                    message   => $ctx->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_task',
                values      => {
                    id        => $info->{id},
                    update_id => $ctx->{update_id},
                    $ctx->{title} ? ( title     => $ctx->{title} )    : (),
                    $status_ids   ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            my ($path) = $db->xarray(
                select     => 'p.path',
                from       => 'tasks t',
                inner_join => 'task_status ts',
                on         => 'ts.id = t.status_id',
                inner_join => 'projects p',
                on         => 'p.id = ts.project_id',
                where      => { 't.id' => $ctx->{id} },
            );

            $db->update_repo(
                {
                    author            => $ctx->{user}->{name},
                    email             => $ctx->{user}->{email},
                    related_update_id => $ctx->{update_id},
                    message           => 'update task '
                      . $ctx->{id}
                      . " [$path]"
                      . ( $ctx->{status} ? ("[$ctx->{status}]") : '' ),
                }
            );
        }
    );

    print "Task updated: $info->{id}.$ctx->{update_id}\n";

    # For testing
    $ctx->{id}               = $info->{id};
    $ctx->{parent_update_id} = $info->{update_id};
    $ctx->{status}           = $status_ids;
    return $ctx->ok('UpdateTask');
}

1;
__END__

=head1 NAME

bif-update - update or comment a topic

=head1 VERSION

0.1.0_9 (2014-04-16)

=head1 SYNOPSIS

    bif update ID [STATUS] [OPTIONS...]

=head1 DESCRIPTION

Add a comment to a topic, possibly setting a new status at the same
time. Valid values for a topics's status depend on the projects it is
associated with. The list of valid status for a project can be found
using L<bif-list-status>(1).

=head1 ARGUMENTS

=over

=item ID

A topic ID, a topic ID.UPDATE_ID, or project PATH. Required.

=item STATUS

The new status for the topic. The status cannot be set when commenting
as a reply to another update.

=back

=head1 OPTIONS

=over

=item --title, -t

The new title for the topic.  The title cannot be set when commenting
as a reply to another update.

=item --message, -m

The message describing this issue in detail. If this option is not used
an editor will be invoked.

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

