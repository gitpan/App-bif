package App::bif::update::issue;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_topic( $self->uuid2id( $self->{id} ), 'issue' );

    my $project_id = $db->xval(
        select => 'project_issues.project_id',
        from   => 'project_issues',
        where  => { 'project_issues.id' => $info->{id} },
    );

    my ( $status_ids, $invalid ) =
      $db->status_ids( $info->{project_id}, 'issue', $self->{status} );

    return $self->err( 'InvalidStatus',
        'unknown status(s): ' . join( ', ', @$invalid ) )
      if @$invalid;

    if ( $self->{reply} ) {
        my $uinfo =
          $self->get_update( $self->{reply}, $info->{first_update_id} );
        $self->{parent_uid} = $uinfo->{id};
    }
    else {
        $self->{parent_uid} = $info->{first_update_id};
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );

    $db->txn(
        sub {
            my $path = $db->xval(
                select => 'p.path',
                from   => 'projects p',
                where  => { 'p.id' => $info->{project_id} },
            );

            $self->{update_id} = $self->new_update(
                message   => $self->{message},
                parent_id => $self->{parent_uid},
            );

            $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id         => $info->{id},
                    update_id  => $self->{update_id},
                    project_id => $info->{project_id},
                    $self->{title} ? ( title     => $self->{title} )   : (),
                    @$status_ids   ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'update_deltas',
                values      => {
                    update_id         => $self->{update_id},
                    new               => 1,
                    action_format     => "update issue %s",
                    action_topic_id_1 => $info->{id},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    print "Issue updated: $info->{project_issue_id}.$self->{update_id}\n";

    # For testing
    $self->{id}               = $info->{id};
    $self->{parent_update_id} = $info->{update_id};
    $self->{status}           = $status_ids;
    return $self->ok('UpdateIssue');
}

1;
__END__

=head1 NAME

bif-update-issue - update an issue

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif update issue ID [STATUS] [OPTIONS...]

=head1 DESCRIPTION

Add a comment to an issue, possibly setting a new status at the same
time. Valid values for an issue's status depend on the project it is
associated with. The list of valid status for a project can be found
using L<bif-list-status>(1).

=head1 ARGUMENTS

=over

=item ID

A issue ID. Required.

=item STATUS

The new status for the topic.

=back

=head1 OPTIONS

=over

=item --title, -t

The new title for the topic.

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

