package App::bif::update::project;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;
    my $info = $self->get_project( $opts->{path} );

    my ( $status_ids, $invalid );
    if ( $opts->{status} ) {

        ( $status_ids, $invalid ) =
          $dbw->status_ids( $info->{id}, 'project', $opts->{status} );

        return $self->err( 'InvalidStatus',
            'unknown status(s): ' . join( ', ', @$invalid ) )
          if @$invalid;
    }

    if ( $opts->{reply} ) {
        my $uinfo =
          $self->get_change( $opts->{reply}, $info->{first_change_id} );
        $opts->{parent_uid} = $uinfo->{id};
    }
    else {
        $opts->{parent_uid} = $info->{first_change_id};
    }

    $opts->{message} ||= $self->prompt_edit( opts => $self );

    my $path = $dbw->xval(
        select => 'p.path',
        from   => 'projects p',
        where  => { id => $info->{id} },
    );

    $dbw->txn(
        sub {
            my $uid = $self->new_change(
                message   => $opts->{message},
                parent_id => $opts->{parent_uid},
            );

            $dbw->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $info->{id},
                    change_id => $uid,
                    $opts->{title} ? ( title     => $opts->{title} )   : (),
                    $status_ids    ? ( status_id => $status_ids->[0] ) : (),
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update project $path (%s)",
                    action_topic_id_1 => $info->{id},
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            $opts->{change_id} = $uid;
        }
    );

    print "Project changed: $path.$opts->{change_id}\n";

    # For testing
    $opts->{id}     = $info->{id};
    $opts->{status} = $status_ids;
    return $self->ok('ChangeProject');
}

1;
__END__

=head1 NAME

=for bif-doc #modify

bif-update-project - update a project

=head1 VERSION

0.1.2 (2014-10-08)

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

