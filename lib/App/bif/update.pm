package App::bif::update;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts   = bif_init(shift);
    my $config = bif_conf;
    my $db     = bif_dbw;

    my $info =
         $db->get_topic( $opts->{id} )
      || $db->get_project( $opts->{id} )
      || bif_err( 'TopicNotFound', 'topic not found: ' . $opts->{id} );

    $info->{update_id} = $info->{first_update_id};

    my $func = __PACKAGE__->can( '_update_' . $info->{kind} )
      || bif_err(
        'Update' . ucfirst( $info->{kind} ) . 'Unimplemented',
        'cannnot update on type: ' . $info->{kind}
      );

    $opts->{lang}   ||= 'en';
    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

    # TODO calculate parent_update_id

    return $func->( $opts, $db, $info );
}

sub _update_project {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;

    my ( $status_ids, $invalid );
    if ( $opts->{status} ) {

        ( $status_ids, $invalid ) =
          $db->status_ids( $info->{id}, 'project', $opts->{status} );

        bif_err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    $opts->{message} ||= prompt_edit( opts => $opts );
    $opts->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $opts->{update_id},
                    parent_id => $info->{update_id},
                    author    => $opts->{author},
                    email     => $opts->{email},
                    message   => $opts->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $info->{id},
                    update_id => $opts->{update_id},
                    $opts->{title} ? ( title     => $opts->{title} )   : (),
                    $status_ids    ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    print "Project updated: $info->{id}.$opts->{update_id}\n";

    # For testing
    $opts->{id}     = $info->{id};
    $opts->{status} = $status_ids;
    return bif_ok( 'UpdateProject', $opts );
}

sub _update_issue {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;

    my ($project_id) = $db->xarray(
        select => 'project_issues.project_id',
        from   => 'project_issues',
        where  => { 'project_issues.id' => $info->{id} },
    );

    my ( $status_ids, $invalid ) =
      $db->status_ids( $info->{project_id}, 'issue', $opts->{status} );

    bif_err( 'InvalidStatus', 'unknown status(s): ' . join( ', ', @$invalid ) )
      if @$invalid;

    $opts->{message} ||= prompt_edit( opts => $opts );
    $opts->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $opts->{update_id},
                    parent_id => $info->{update_id},
                    author    => $opts->{author},
                    email     => $opts->{email},
                    message   => $opts->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id         => $info->{id},
                    update_id  => $opts->{update_id},
                    project_id => $info->{project_id},
                    $opts->{title} ? ( title     => $opts->{title} )   : (),
                    @$status_ids   ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    print "Issue updated: $info->{project_issue_id}.$opts->{update_id}\n";

    # For testing
    $opts->{id}               = $info->{id};
    $opts->{parent_update_id} = $info->{update_id};
    $opts->{status}           = $status_ids;
    return bif_ok( 'UpdateIssue', $opts );
}

sub _update_task {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;

    my ( $status_ids, $invalid );
    if ( $opts->{status} ) {
        my ($project_id) = $db->xarray(
            select     => 'task_status.project_id',
            from       => 'tasks',
            inner_join => 'task_status',
            on         => 'task_status.id = tasks.status_id',
            where      => { 'tasks.id' => $info->{id} },
        );

        ( $status_ids, $invalid ) =
          $db->status_ids( $project_id, 'task', $opts->{status} );

        bif_err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    $opts->{message} ||= prompt_edit( opts => $opts );
    $opts->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $opts->{update_id},
                    parent_id => $info->{update_id},
                    author    => $opts->{author},
                    email     => $opts->{email},
                    message   => $opts->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_update_task',
                values      => {
                    id        => $info->{id},
                    update_id => $opts->{update_id},
                    $opts->{title} ? ( title     => $opts->{title} )   : (),
                    $status_ids    ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    print "Task updated: $info->{id}.$opts->{update_id}\n";

    # For testing
    $opts->{id}               = $info->{id};
    $opts->{parent_update_id} = $info->{update_id};
    $opts->{status}           = $status_ids;
    return bif_ok( 'UpdateTask', $opts );
}

1;
__END__

=head1 NAME

bif-update - update or comment a topic

=head1 VERSION

0.1.0 (yyyy-mm-dd)

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

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

