package App::bif::sync;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0_10';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $ctx = App::bif::Context->new($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw   = $ctx->dbw;
    my @repos = $dbw->xhashes(
        select     => [ 'r.id', 'r.alias', 'rl.location', 't.uuid' ],
        from       => 'repos r',
        inner_join => 'topics t',
        on         => 't.id = r.id',
        inner_join => 'repo_locations rl',
        on    => 'rl.id = r.default_location_id',
        where => 'r.local IS NULL',
    );

    return $ctx->err( 'SyncNone', 'no hubs registered' ) unless @repos;

    $|++;    # no buffering

    foreach my $hub (@repos) {
        my $error;
        my $cv = AE::cv;

        my $client = Bif::Client->new(
            db       => $dbw,
            hub      => $hub->{location},
            debug    => $ctx->{debug},
            debug_bs => $ctx->{debug_bs},
            on_error => sub {
                $error = shift;
                $cv->send;
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
            print STDERR "$hub->{alias}: $line";
        };

        my $coro = async {
            eval {
                $dbw->txn(
                    sub {
                        my $previous = $dbw->get_max_update_id;
                        my $status   = $client->sync_repo( $hub->{id} );

                        if (   $status eq 'RepoMatch'
                            or $status eq 'RepoImported' )
                        {
                            my @projects = $dbw->xhashes(
                                select => ['p.id'],
                                from   => 'projects p',
                                where  => {
                                    'p.repo_id' => $hub->{id},
                                    'p.local'   => 1,
                                },
                            );

                            foreach my $p (@projects) {
                                $status = $client->sync_project( $p->{id} );

                                unless ( $status eq 'ProjectMatch'
                                    or $status eq 'ProjectImported' )
                                {
                                    $dbw->rollback;
                                    $error = $status;
                                }
                            }
                        }
                        else {
                            $dbw->rollback;
                            $error = $status;
                        }

                        # Catch up on errors
                        undef $stderr_watcher;
                        $stderr->blocking(0);
                        while ( my $line = $stderr->getline ) {
                            print STDERR "$hub->{alias}: $line";
                        }

                        return if $error;

                        my $current = $dbw->get_max_update_id;
                        my $delta   = $current - $previous;

                        $dbw->update_repo(
                            {
                                author => $ctx->{user}->{name},
                                email  => $ctx->{user}->{email},
                                message =>
"sync $hub->{location} [+$delta] $ctx->{message}",
                            }
                        );

                        return;
                    }
                );
            };

            $error .= $@ if $@;
            $client->disconnect;
            return $cv->send( !$error );
        };

        next if $cv->recv;
        return $ctx->err( 'Unknown', $error );

    }

    return $ctx->ok('Sync');
}

1;

__END__

=head1 NAME

bif-sync -  exchange updates with repos

=head1 VERSION

0.1.0_10 (2014-04-17)

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

