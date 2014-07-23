package App::bif::new::identity;
use strict;
use warnings;
use App::bif::Context;
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    $ctx->{name} ||= prompt( 'Name:', '' )
      || return $ctx->err( 'NameRequired', 'name is required' );

    $ctx->{method} ||= prompt( 'Contact Method:', 'email' )
      || return $ctx->err( 'MethodRequired', 'method is required' );

    $ctx->{value} ||= prompt( 'Contact Value:', '' )
      || return $ctx->err( 'ValueRequired', 'value is required' );

    $ctx->{message} ||= '';

    $db->txn(
        sub {
            my $ruid  = $db->nextval('updates');
            my $id    = $db->nextval('topics');
            my $ecmid = $db->nextval('topics');
            my $uid   = $ctx->new_update( message => $ctx->{message} );

            $db->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    id        => $id,
                    update_id => $uid,
                    kind      => 'identity',
                    name      => $ctx->{name},
                },
            );

            $db->xdo(
                insert_into => 'func_new_identity',
                values      => {
                    id        => $id,
                    update_id => $uid,
                },
            );

            $db->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    entity_id => $id,
                    method    => $ctx->{method},
                    mvalue    => bv( $ctx->{value}, DBI::SQL_VARCHAR ),
                },
            );

            $db->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    update_id                 => $uid,
                    id                        => $id,
                    contact_id                => $id,
                    default_contact_method_id => $ecmid,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $ctx->update_localhub(
                {
                    id                => $ruid,
                    message           => "new identity $id [$ctx->{name}]",
                    related_update_id => $uid,
                }
            );

            printf( "Identity created: %d\n", $id );

            # For test scripts
            $ctx->{id}        = $id;
            $ctx->{update_id} = $uid;
        }
    );

    return $ctx->ok('NewIdentity');
}

1;
__END__

=head1 NAME

bif-new-identity - create a new identity in the repository

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif new identity [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The C<bif new identity> command creates a new identity representing an
ididentity or an organisation.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the identity.

=item METHOD

The default contact method type, typically "phone", "email", etc.

=item VALUE

The value of the default contact method, i.e. the phone number, the
email address, etc.

=item --message, -m MESSAGE

The creation message, set to "Created" by default.

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

