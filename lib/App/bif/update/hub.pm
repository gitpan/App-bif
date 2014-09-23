package App::bif::update::hub;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_hub( $self->{id} );

    if ( $self->{reply} ) {
        my $uinfo =
          $self->get_change( $self->{reply}, $info->{first_change_id} );
        $self->{parent_uid} = $uinfo->{id};
    }
    else {
        $self->{parent_uid} = $info->{first_change_id};
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );

    $db->txn(
        sub {
            my $uid = $self->new_change(
                message   => $self->{message},
                parent_id => $self->{parent_uid},
            );

            $db->xdo(
                insert_into => 'func_change_hub',
                values      => {
                    change_id => $uid,
                    id        => $info->{id},
                    name      => $self->{name},
                },
            );

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update hub $self->{id} (%s)",
                    action_topic_id_1 => $info->{id},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            print "Hub changed: $self->{id}.$uid\n";
        }
    );

    return $self->ok('ChangeHub');
}

1;
__END__

=head1 NAME

bif-update-hub - update or comment a hub

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif update hub ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-update-hub> command adds a comment to a hub, possibly setting
a new name at the same time.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An hub ID, required.

=item --name, -n

The new name for the hub.

=item --message, -m

The message describing this change in detail.

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

