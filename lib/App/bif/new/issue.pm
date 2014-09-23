package App::bif::new::issue;
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
          $db->status_ids( $pinfo->{id}, 'issue', $self->{status} );

        return $self->err( 'InvalidStatus',
            'unknown status: ' . join( ', ', @$invalid ) )
          if @$invalid;

        $self->{status_id} = $status_ids->[0];
    }
    else {
        $self->{status_id} = $db->xval(
            select => 'id',
            from   => 'issue_status',
            where  => { project_id => $pinfo->{id}, def => 1 },
        );
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );
    $db->txn(
        sub {
            my $id       = $db->nextval('topics');
            my $topic_id = $db->nextval('topics');

            my $uid = $self->new_change( message => $self->{message}, );

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $topic_id,
                    kind      => 'issue',
                },
            );

            $db->xdo(
                insert_into => 'func_new_issue',
                values      => {
                    id        => $id,
                    topic_id  => $topic_id,
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
                    action_format     => "new issue (%s)",
                    action_topic_id_1 => $topic_id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Issue created: %d\n", $id );

            # For test scripts
            $self->{id}        = $id;
            $self->{topic_id}  = $topic_id;
            $self->{change_id} = $uid;
        }
    );

    return $self->ok('NewIssue');
}

1;
__END__

=head1 NAME

bif-new-issue - add a new issue to a project

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif new issue [PATH] [TITLE...] [OPTIONS...]

=head1 DESCRIPTION

Add a new issue to a project.

=head1 ARGUMENTS

=over

=item PATH

The path of the project to which this issue applies. Prompted for if
not provided.

=item TITLE

The summary of this issue. Prompted for if not provided.

=back

=head1 OPTIONS

=over

=item --status, -s STATE

The initial status of the issue. This must be a valid status for the
project as output by the L<bif-list-status>(1) command. A default is
used if not provided.

=item --message, -m MESSAGE

The body of the issue. An editor will be invoked if not provided.

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

