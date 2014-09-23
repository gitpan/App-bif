package App::bif::new::host;
use strict;
use warnings;
use parent 'App::bif::Context';
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;

    $self->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $self->{message} ||= "New host $self->{name}";

    my $provider;
    if ( $self->{name} =~ s/(.*?):(.*)/$2/ ) {
        $provider = $db->xhashref(
            select     => [qw/p.id e.name/],
            from       => 'providers p',
            inner_join => 'entities e',
            on         => 'e.id = p.id',
            where      => { 'e.name' => $1 },
        );

        return $self->err( 'ProviderNotFound', 'provider not found: ' . $1 )
          unless $provider;
    }
    else {
        my @providers = $db->xhashrefs(
            select     => [qw/p.id e.name/],
            from       => 'providers p',
            inner_join => 'entities e',
            on         => 'e.id = p.id',
        );

        return $self->err( 'NoProvider', 'a host needs a provider' )
          unless @providers;

        return $self->err( 'AmbiguousProvider', 'ambiguous provider' )
          if @providers > 1;

        $provider = $providers[0];
    }

    $db->txn(
        sub {
            my $uid = $self->new_change( message => $self->{message}, );

            my $id = $db->nextval('topics');

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    kind      => 'host',
                },
            );

            $db->xdo(
                insert_into => 'func_new_host',
                values      => {
                    id          => $id,
                    change_id   => $uid,
                    provider_id => $provider->{id},
                    name        => $self->{name},
                },
            );

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new host (%s) $self->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Host created: %s:%s\n", $provider->{name}, $self->{name} );

            # For test scripts
            $self->{id}        = $id;
            $self->{change_id} = $uid;
        }
    );

    return $self->ok('NewHost');
}

1;
__END__

=head1 NAME

bifhub-new-host - create a new host in the repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bifhub new host [NAME]

=head1 DESCRIPTION

The C<bifhub new host> command creates a new host of bif hub hosting.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the host in the format [PROVIDER:]NAME. The provider part
is only required when there is more than one provider in the
repository.

=item --message, -m MESSAGE

The creation message, set to "" by default.

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

