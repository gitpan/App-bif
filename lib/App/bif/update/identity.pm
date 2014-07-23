package App::bif::update::identity;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx  = App::bif::Context->new(shift);
    my $db   = $ctx->dbw;
    my $info = $ctx->get_topic( $ctx->{id} );

    return $ctx->err( 'IdentityNotFound', "identity not found: $ctx->{id}" )
      unless $info;

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );

    $db->txn(
        sub {
            my $uid = $ctx->new_update( message => $ctx->{message}, );

            $db->xdo(

                # TODO This shuld be update_entity
                insert_into => 'func_update_identity',
                values      => {
                    update_id => $uid,
                    id        => $info->{id},
                    name      => $ctx->{name},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $ctx->update_localhub(
                {
                    related_update_id => $uid,
                    message           => 'update identity ' . "$info->{id}",
                }
            );

            print "Identity updated: $ctx->{id}.$uid\n";
        }
    );

    return $ctx->ok('UpdateIdentity');
}

1;
__END__

=head1 NAME

bif-update-identity - update or comment an identity

=head1 VERSION

0.1.0_26 (2014-07-23)

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

