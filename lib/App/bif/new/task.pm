package App::bif::new::task;
use strict;
use warnings;
use parent 'App::bif::Context';
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;

    $self->{title} ||= prompt( 'Title:', '' )
      || return $self->err( 'TitleRequired', 'title is required' );

    if ( !$self->{path} ) {

        my @paths = $db->xarrayrefs(
            select    => [ "p.path || COALESCE('\@' || h.name,'') AS path", ],
            from      => 'projects p',
            left_join => 'hubs h',
            on        => 'h.id = p.hub_id',
            order_by  => 'path',
        );

        if ( 0 == @paths ) {
            return $self->err( 'NoProjectInRepo', 'task needs a project' );
        }
        elsif ( 1 == @paths ) {
            $self->{path} = $paths[0]->[0];
        }
        else {
            $self->{path} = prompt( 'Project:', $paths[0]->[0] )
              || return $self->err( 'ProjectRequired', 'project is required' );
        }
    }

    my $pinfo = $self->get_project( $self->{path} );

    if ( $self->{status} ) {
        my ( $status_ids, $invalid ) =
          $db->status_ids( $pinfo->{id}, 'task', $self->{status} );

        return $self->err( 'InvalidStatus',
            'unknown status: ' . join( ', ', @$invalid ) )
          if @$invalid;

        $self->{status_id} = $status_ids->[0];
    }
    else {
        $self->{status_id} = $db->xval(
            select => 'id',
            from   => 'task_status',
            where  => { project_id => $pinfo->{id}, def => 1 },
        );
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );

    $db->txn(
        sub {
            my $id = $db->nextval('topics');
            my $uid = $self->new_change( message => $self->{message}, );

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    kind      => 'task',
                },
            );

            $db->xdo(
                insert_into => 'func_new_task',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    status_id => $self->{status_id},
                    title     => $self->{title},
                },
            );

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => 'new task (%s)',
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Task created: %d\n", $id );

            # For test scripts
            $self->{id}        = $id;
            $self->{change_id} = $uid;
        }
    );

    return $self->ok('NewTask');
}

1;
__END__

=head1 NAME

bif-new-task - add a new task to a project

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif new task [PATH] [TITLE...] [OPTIONS...]

=head1 DESCRIPTION

Add a new task to a project.

=head1 ARGUMENTS

=over

=item PATH

The path of the project to which this task applies. Prompted for if not
provided.

=item TITLE

The summary of this task. Prompted for if not provided.

=back

=head1 OPTIONS

=over

=item --status, -s STATE

The initial status of the task. This must be a valid status for the
project as output by the L<bif-list-status>(1) command. A default is
used if not provided.

=item --message, -m MESSAGE

The body of the task. An editor will be invoked if not provided.

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

