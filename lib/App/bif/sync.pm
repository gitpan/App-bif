package App::bif::sync;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $ctx = App::bif::Context->new($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw   = $ctx->dbw;
    my @repos = $dbw->xhashes(
        select     => [ 'r.id', 'r.location', 't.uuid' ],
        from       => 'repos r',
        inner_join => 'topics t',
        on         => 't.id = r.id',
        where      => 'r.local IS NULL',
    );

    $|++;    # no buffering

    my $err;
    my $status;
    my $cv = AE::cv;

    foreach my $repo (@repos) {
        $err    = undef;
        $status = undef;

        my $client = Bif::Client->new(
            db       => $dbw,
            hub      => $repo->{location},
            on_error => sub {
                $err = shift;
            },
        );

        my $stderr = $client->child->stderr;

        my $stderr_watcher;
        $stderr_watcher = AE::io $stderr, 0, sub {
            my $line = $stderr->getline;
            if ( !defined $line ) {
                undef $stderr_watcher;
                return;
            }
            print STDERR 'hub: ' . $line;
        };

        my $coro = async {
            eval {
                $dbw->txn(
                    sub {
                        my $previous = $dbw->get_max_update_id;

                        $status = $client->sync_repo( $repo->{id} );

                        # Catch up on errors
                        undef $stderr_watcher;
                        $stderr->blocking(0);
                        while ( my $line = $stderr->getline ) {
                            print STDERR 'hub: ' . $line;
                        }

                        return unless $status->[0];

                        my $current = $dbw->get_max_update_id;
                        my $delta   = $current - $previous;

                        $dbw->update_repo(
                            {
                                author  => $ctx->{user}->{name},
                                email   => $ctx->{user}->{email},
                                message => "sync $repo->{location} [+$delta]",
                            }
                        );

                        return;
                    }
                );
            };

            if ($@) {
                $status = [ 0, 'InternalError', $@ ];
            }

            if ( $status->[0] ) {
                print "$repo->{location}: $status->[2]\n";
            }

            $client->disconnect;
            $cv->send;
            return;
        };

        my $sig;
        $sig = AE::signal 'INT', sub {
            warn 'INT';
            undef $sig;
            $client->disconnect;
            $cv->send;
        };

        $cv->recv;
    }

    return $ctx->ok( $status->[1], $status->[2] ) if $status->[0];
    return $ctx->err( $status->[1], $status->[2] );
}

1;
__END__

=head1 NAME

bif-sync -  exchange updates with repos

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif sync [OPTIONS...]

=head1 DESCRIPTION

The C<bif sync> command connects to all remote repositories registered
as hubs in the local repository and exchanges updates.

=head1 ARGUMENTS & OPTIONS

To be documented.

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

