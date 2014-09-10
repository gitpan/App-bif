package App::bif::pull::identity;
use strict;
use warnings;
use parent 'App::bif::Context';
use AnyEvent;
use Bif::Client;
use Coro;
use Log::Any '$log';

our $VERSION = '0.1.0_27';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    $|++;

    my $self = __PACKAGE__->new($opts);
    my $cv   = AE::cv;
    my $dbw  = $self->dbw;
    my $error;

    my $client = Bif::Client->new(
        name          => $self->{location},
        db            => $dbw,
        location      => $self->{location},
        debug         => $self->{debug},
        debug_bifsync => $self->{debug_bifsync},
        on_error      => sub {
            $error = shift;
            $cv->send;
        },
    );

    my $coro = async {
        eval {
            $dbw->txn(
                sub {
                    $|++;
                    print "Importing identity from $self->{location}";
                    my $status = $client->bootstrap_identity;

                    unless ( $status eq 'IdentityImported' ) {
                        $dbw->rollback;
                        $error = "unexpected status received: $status";
                    }
                }
            );
        };

        if ($@) {
            $error .= $@;
        }
        print "\n";

        $client->disconnect;
        return $cv->send( !$error );
    };

    return $self->err( 'Unknown', $error ) unless $cv->recv;
    return $self->ok('PullIdentity');
}

1;
__END__

=head1 NAME

bif-pull-identity - import an identity from a repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif pull identity LOCATION [OPTIONS...]

=head1 DESCRIPTION

The B<bif-pull-identity> command imports an identity from a repository.

=head1 ARGUMENTS & OPTIONS

=over

=item LOCATION

The location of the identity repository.

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

