package App::bif::new::issue;
use strict;
use warnings;
use Bif::Mo;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    $opts->{title} ||= prompt( 'Title:', '' )
      || return $self->err( 'TitleRequired', 'title is required' );

    if ( !$opts->{path} ) {

        my @paths = $dbw->xarrayrefs(
            select    => 'p.fullpath',
            from      => 'projects p',
            left_join => 'hubs h',
            on        => 'h.id = p.hub_id',
            order_by  => 'path',
        );

        if ( 0 == @paths ) {
            return $self->err( 'NoProjectInRepo', 'task needs a project' );
        }
        elsif ( 1 == @paths ) {
            $opts->{path} = $paths[0]->[0];
        }
        else {
            $opts->{path} = prompt( 'Project:', $paths[0]->[0] )
              || return $self->err( 'ProjectRequired', 'project is required' );
        }
    }

    my $pinfo = $self->get_project( $opts->{path} );

    if ( $opts->{status} ) {
        my ( $status_ids, $invalid ) =
          $dbw->status_ids( $pinfo->{id}, 'issue', $opts->{status} );

        return $self->err( 'InvalidStatus',
            'unknown status: ' . join( ', ', @$invalid ) )
          if @$invalid;

        $opts->{issue_status_id} = $status_ids->[0];
    }
    else {
        $opts->{issue_status_id} = $dbw->xval(
            select => 'id',
            from   => 'issue_status',
            where  => { project_id => $pinfo->{id}, def => 1 },
        );
    }

    $opts->{message} ||= $self->prompt_edit(
        opts => $self,
        txt  => "

# Things to keep in mind when reporting a software issue:
#
#   - What are goal you trying to achieve?
#
#   - What version of software and libraries are installed?
#
#   - What commands are you running?
#
#   - What (output) did you expect (to see)?
#
#   - What (output) actually occured?
#
"
    );
    $dbw->txn(
        sub {
            my $id       = $dbw->nextval('topics');
            my $topic_id = $dbw->nextval('topics');

            my $uid = $self->new_change( message => $opts->{message}, );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $topic_id,
                    kind      => 'issue',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_issue',
                values      => {
                    id              => $id,
                    topic_id        => $topic_id,
                    change_id       => $uid,
                    issue_status_id => $opts->{issue_status_id},
                    title           => $opts->{title},
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new issue (%s)",
                    action_topic_id_1 => $topic_id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Issue created: %d\n", $id );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{topic_id}  = $topic_id;
            $opts->{change_id} = $uid;
        }
    );

    return $self->ok('NewIssue');
}

1;
__END__

=head1 NAME

=for bif-doc #create

bif-new-issue - add a new issue to a project

=head1 VERSION

0.1.4 (2014-10-27)

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

