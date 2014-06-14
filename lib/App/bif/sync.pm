package App::bif::sync;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0_25';

my $stderr;
my $stderr_watcher;

sub cleanup_errors {
    my $hub = shift;

    undef $stderr_watcher;
    $stderr->blocking(0);

    while ( my $line = $stderr->getline ) {
        print STDERR "$hub: $line";
    }

    return;
}

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $ctx = App::bif::Context->new($opts);
    my $dbw = $ctx->dbw;

    if ( $opts->{hub} ) {
        foreach my $name ( @{ $opts->{hub} } ) {
            my @rl = $dbw->get_hub_repos($name);
            $ctx->err( 'HubNotFound', 'hub not found: ' . $name )
              unless @rl;
        }
    }

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my @hubs = $dbw->xhashes(
        select     => [ 'h.id', 'h.name', 'hr.location', 't.uuid' ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        inner_join => 'hub_repos hr',
        on    => 'hr.id = h.default_repo_id',
        where => {
            'h.local' => undef,
            $opts->{hub} ? ( 'h.name' => $opts->{hub} ) : (),
        },
    );

    return $ctx->err( 'SyncNone', 'no (matching) hubs registered' )
      unless @hubs;

    $|++;    # no buffering

    foreach my $hub (@hubs) {
        my $error;
        my $cv = AE::cv;
        $ctx->lprint("$hub->{name}: connecting...");

        my $client = Bif::Client->new(
            db       => $dbw,
            location => $hub->{location},
            debug    => $ctx->{debug},
            debug_bs => $ctx->{debug_bs},
            on_error => sub {
                $error = shift;
                $cv->send;
            },
        );

        $stderr = $client->child->stderr;

        $stderr_watcher = AE::io $stderr, 0, sub {
            my $line = $stderr->getline;
            if ( !defined $line ) {
                undef $stderr_watcher;
                return;
            }
            print STDERR "$hub->{name}: $line";
        };

        my $coro = async {
            eval {
                $dbw->txn(
                    sub {
                        $ctx->update_repo(
                            {
                                message => "sync $hub->{location} "
                                  . $ctx->{message},
                            }
                        );

                        $client->on_update(
                            sub {
                                $ctx->lprint("$hub->{name}: $_[0]");
                            }
                        );

                        my $previous = $dbw->get_max_update_id;
                        my $status   = $client->sync_hub( $hub->{id} );

                        unless ( $status eq 'RepoMatch'
                            or $status eq 'RepoSync' )
                        {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return cleanup_errors( $hub->{name} );

                        }

                        if ( $status eq 'RepoSync' ) {
                            $status = $client->transfer_hub_updates;
                            if ( $status ne 'TransferHubUpdates' ) {
                                $dbw->rollback;
                                $error = "unexpected status received: $status";
                                return cleanup_errors( $hub->{name} );
                            }
                        }

                        $status = $client->sync_projects;

                        unless ( $status eq 'ProjectSync' ) {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return cleanup_errors( $hub->{name} );
                        }

                        $status = $client->transfer_project_related_updates;

                        if ( $status ne 'TransferProjectRelatedUpdates' ) {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return cleanup_errors( $hub->{name} );
                        }
                        print "\n";

                        my $current = $dbw->get_max_update_id;
                        my $delta   = $current - $previous;

                        return cleanup_errors;
                    }
                );
            };

            if ($@) {
                $error .= $@;
                print "\n";
            }

            $client->disconnect;
            return $cv->send( !$error );
        };

        if ( $cv->recv ) {
            next;
        }

        return $ctx->err( 'Unknown', $error );

    }

    # TODO make this dependent on how many updates received/made since the last
    # analyze
    $dbw->do('ANALYZE');

    return $ctx->ok('Sync');
}

1;

__END__

=head1 NAME

bif-sync -  exchange updates with hubs

=head1 VERSION

0.1.0_25 (2014-06-14)

=head1 SYNOPSIS

    bif sync [OPTIONS...]

=head1 DESCRIPTION

The C<bif sync> command connects to all remote repositories registered
as hubs in the local repository and exchanges updates.

=head1 ARGUMENTS & OPTIONS

=over

=item --hub, -H HUB

Limit the hubs to sync with. This option can be used multiple times.

=item --path, -p PATH

Limit the projects to sync. This option can be used multiple times.

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

