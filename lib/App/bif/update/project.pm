package App::bif::update::project;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_project( $self->{path} );

    my ( $status_ids, $invalid );
    if ( $self->{status} ) {

        ( $status_ids, $invalid ) =
          $db->status_ids( $info->{id}, 'project', $self->{status} );

        return $self->err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    if ( $self->{reply} ) {
        my $uinfo =
          $self->get_change( $self->{reply}, $info->{first_change_id} );
        $self->{parent_uid} = $uinfo->{id};
    }
    else {
        $self->{parent_uid} = $info->{first_change_id};
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );

    my $path = $db->xval(
        select => 'p.path',
        from   => 'projects p',
        where  => { id => $info->{id} },
    );

    $db->txn(
        sub {
            my $uid = $self->new_change(
                message   => $self->{message},
                parent_id => $self->{parent_uid},
            );

            $db->xdo(
                insert_into => 'func_change_project',
                values      => {
                    id        => $info->{id},
                    change_id => $uid,
                    $self->{title} ? ( title     => $self->{title} )   : (),
                    $status_ids    ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update project $path (%s)",
                    action_topic_id_1 => $info->{id},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            $self->{change_id} = $uid;
        }
    );

    print "Project changed: $path.$self->{change_id}\n";

    # For testing
    $self->{id}     = $info->{id};
    $self->{status} = $status_ids;
    return $self->ok('ChangeProject');
}

1;
__END__

=head1 NAME

bif-update-project - update a project

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif update project ID [STATUS] [OPTIONS...]

=head1 DESCRIPTION

Add a comment to a project, possibly setting a new status at the same
time. Valid values for a project's status depend on the project it is
associated with. The list of valid status for a project can be found
using L<bif-list-status>(1).

=head1 ARGUMENTS

=over

=item PATH

A project PATH. Required.

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

