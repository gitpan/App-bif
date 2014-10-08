package App::bif::new::provider;
use strict;
use warnings;
use Bif::Mo;
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    $opts->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $opts->{method} ||= prompt( 'Contact Method:', 'email' )
      || return $self->err( 'MethodRequired', 'method is required' );

    $opts->{value} ||= prompt( 'Contact Value:', '' )
      || return $self->err( 'ValueRequired', 'value is required' );

    $opts->{message} ||= "New provider $opts->{name}";

    $dbw->txn(
        sub {
            my $id    = $dbw->nextval('topics');
            my $ecmid = $dbw->nextval('topics');
            my $uid   = $self->new_change( message => $opts->{message}, );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    kind      => 'provider',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    name      => $opts->{name},
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $ecmid,
                    change_id => $uid,
                    kind      => 'entity_contact_method',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    change_id => $uid,
                    id        => $ecmid,
                    entity_id => $id,
                    method    => $opts->{method},
                    mvalue    => bv( $opts->{value}, DBI::SQL_VARCHAR ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    change_id                 => $uid,
                    id                        => $id,
                    contact_id                => $id,
                    default_contact_method_id => $ecmid,
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_provider',
                values      => {
                    id        => $id,
                    change_id => $uid,
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new provider (%s) $opts->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Provider created: %d\n", $id );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    return $self->ok('NewProvider');
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-new-provider - create a new provider in the repository

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif new provider [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-provider> command creates a new provider of bif hub
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

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

