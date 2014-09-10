package App::bif::new::provider;
use strict;
use warnings;
use parent 'App::bif::Context';
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;

    $self->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $self->{method} ||= prompt( 'Contact Method:', 'email' )
      || return $self->err( 'MethodRequired', 'method is required' );

    $self->{value} ||= prompt( 'Contact Value:', '' )
      || return $self->err( 'ValueRequired', 'value is required' );

    $self->{message} ||= '';

    $db->txn(
        sub {
            my $id    = $db->nextval('topics');
            my $ecmid = $db->nextval('topics');
            my $uid   = $self->new_update( message => $self->{message}, );

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    update_id => $uid,
                    kind      => 'provider',
                },
            );

            $db->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    id        => $id,
                    update_id => $uid,
                    name      => $self->{name},
                },
            );

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $ecmid,
                    update_id => $uid,
                    kind      => 'entity_contact_method',
                },
            );

            $db->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    entity_id => $id,
                    method    => $self->{method},
                    mvalue    => bv( $self->{value}, DBI::SQL_VARCHAR ),
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
                insert_into => 'func_new_provider',
                values      => {
                    id        => $id,
                    update_id => $uid,
                },
            );

            $db->xdo(
                insert_into => 'update_deltas',
                values      => {
                    update_id         => $uid,
                    new               => 1,
                    action_format     => "new provider %s ($self->{name})",
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            printf( "Provider created: %d\n", $id );

            # For test scripts
            $self->{id}        = $id;
            $self->{update_id} = $uid;
        }
    );

    return $self->ok('NewProvider');
}

1;
__END__

=head1 NAME

bifhub-new-provider - create a new provider in the repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bifhub new provider [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The C<bifhub new provider> command creates a new provider of bif hub
hosting.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the provider.

=item METHOD

The default contact method type, typically "phone", "email", etc.

=item VALUE

The value of the default contact method, i.e. the phone number, the
email address, etc.

=item --message, -m MESSAGE

The creation message, set to "Created" by default.

=back

=head1 SEE ALSO

L<bifhub>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

