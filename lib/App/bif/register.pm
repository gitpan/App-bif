package App::bif::register;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;
use Log::Any '$log';
use Path::Tiny;

our $VERSION = '0.1.0_26';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $ctx = App::bif::Context->new($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw = $ctx->dbw;

    if ( $ctx->{location} =~ m!^ssh://(.+)! ) {
    }
    elsif ( -d $ctx->{location} ) {
        $ctx->{location} = path( $ctx->{location} )->realpath;
    }
    else {
        return $ctx->err( 'HubNotFound', 'hub not found: %s',
            $ctx->{location} );
    }

    $log->debug("register hub: $ctx->{location}");

    my @locations = $dbw->get_hub_repos( $ctx->{location} );

    return $ctx->err(
        'RepoExists', 'hub already registered: %s (%s)',
        $locations[0]->{location}, ( $locations[0]->{name} || '' )
    ) if (@locations);

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db            => $dbw,
        location      => $ctx->{location},
        debug         => $ctx->{debug},
        debug_bifsync => $ctx->{debug_bifsync},
        on_error      => sub {
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
        print STDERR "$ctx->{location}: $line";

    };

    my $coro = async {
        eval {
            $dbw->txn(
                sub {
                    $ctx->update_localhub(
                        {
                            message => "register $ctx->{location}",
                        }
                    );

                    $client->on_update(
                        sub {
                            $ctx->lprint("$ctx->{location}: $_[0]");
                        }
                    );

                    my $previous = $dbw->get_max_update_id;
                    my $status   = $client->register;

                    print "\n";

                    # Catch up on errors
                    undef $stderr_watcher;
                    $stderr->blocking(0);
                    while ( my $line = $stderr->getline ) {
                        print STDERR "$ctx->{location}: $line";
                    }

                    if ( $status ne 'RepoImported' ) {
                        $error = $status;
                        $dbw->rollback;
                        return $status;
                    }

                    my $current = $dbw->get_max_update_id;
                    my $delta   = $current - $previous;

                    my ( $hid, $rid, $name ) = $dbw->xarray(
                        select     => [ 'h.id', 'hr.id', 'h.name' ],
                        from       => 'hub_repos hr',
                        inner_join => 'hubs h',
                        on         => 'h.id = hr.hub_id',
                        where => { 'hr.location' => $ctx->{location} },
                    );

                    $dbw->xdo(
                        update => 'hubs',
                        set    => { default_repo_id => $rid },
                        where  => { id => $hid },
                    );

                    print "Hub registered: $name\n";
                    return $status;
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

    return $ctx->ok('Register') if $cv->recv;
    return $ctx->err( 'Unknown', $error );

}

1;
__END__

=head1 NAME

bif-register -  register with a remote repository

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif register LOCATION [OPTIONS...]

=head1 DESCRIPTION

The C<bif register> command connects to a hub repository to obtain the
list of projects hosted there.  A hub has a name (use the C<list hubs>
command to display it) which is useable after registration with all
other hub-aware commands to save typing the full address.

The retrieved project list is stored locally and is used by the C<pull
project>, and C<push issue> commands, and updated by the C<sync>
command.

=head1 ARGUMENTS & OPTIONS

=over

=item LOCATION

The location of a remote repository.

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

