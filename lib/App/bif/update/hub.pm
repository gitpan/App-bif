package App::bif::update::hub;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;
    my $info = $self->get_hub( $opts->{id} );

    if ( $opts->{reply} ) {
        my $uinfo =
          $self->get_change( $opts->{reply}, $info->{first_change_id} );
        $opts->{parent_uid} = $uinfo->{id};
    }
    else {
        $opts->{parent_uid} = $info->{first_change_id};
    }

    $opts->{message} ||= $self->prompt_edit( opts => $self );

    $dbw->txn(
        sub {
            my $uid = $self->new_change(
                message   => $opts->{message},
                parent_id => $opts->{parent_uid},
            );

            $dbw->xdo(
                insert_into => 'func_update_hub',
                values      => {
                    change_id => $uid,
                    id        => $info->{id},
                    name      => $opts->{name},
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update hub $opts->{id} (%s)",
                    action_topic_id_1 => $info->{id},
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            print "Hub changed: $opts->{id}.$uid\n";
        }
    );

    return $self->ok('ChangeHub');
}

1;
__END__

=head1 NAME

=for bif-doc #modify

bif-update-hub - update or comment a hub

=head1 VERSION

0.1.2 (2014-10-08)

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

