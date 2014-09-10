package App::bif::update::identity;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_topic( $self->{id} );

    return $self->err( 'IdentityNotFound', "identity not found: $self->{id}" )
      unless $info;

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
            my $uid = $self->new_update(
                message   => $self->{message},
                parent_id => $self->{parent_uid},
            );

            $db->xdo(

                # TODO This shuld be update_entity
                insert_into => 'func_update_identity',
                values      => {
                    update_id => $uid,
                    id        => $info->{id},
                    name      => $self->{name},
                },
            );

            $db->xdo(
                insert_into => 'update_deltas',
                values      => {
                    update_id         => $uid,
                    new               => 1,
                    action_format     => "update identity %s",
                    action_topic_id_1 => $info->{id},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            print "Identity updated: $self->{id}.$uid\n";
        }
    );

    return $self->ok('UpdateIdentity');
}

1;
__END__

=head1 NAME

bif-update-identity - update or comment an identity

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif update identity ID [OPTIONS...]

=head1 DESCRIPTION

The "bif update identity" command adds a comment to an identity,
possibly setting a new name at the same time.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An identity ID, required.

=item --name, -n

The new name for the identity.

=item --message, -m

The message describing this update in detail.

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

