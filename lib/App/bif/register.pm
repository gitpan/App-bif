package App::bif::register;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;
use Log::Any '$log';
use Path::Tiny;

our $VERSION = '0.1.0_13';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $ctx = App::bif::Context->new($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw = $ctx->dbw;

    if ( -d $ctx->{hub} ) {
        $ctx->{hub} = path( $ctx->{hub} )->realpath;
        $ctx->{alias} ||= $ctx->{hub}->basename;
    }
    elsif ( $ctx->{hub} !~ m!^bif://! ) {
        return $ctx->err( 'HubNotFound', 'hub not found: %s', $ctx->{hub} );
        ( $ctx->{alias} ||= $ctx->{hub} ) =~ s!.*/!!;
        $ctx->{alias} =~ s!/!!;    # trailing '/'
    }

    $log->debug("register hub: $ctx->{hub}");
    $log->debug("register alias: $ctx->{alias}");

    my @repos = $dbw->get_repo_locations( $ctx->{hub} );

    return $ctx->err(
        'RepoExists',
        'hub (or alias) already registered: %s (%s)',
        $repos[0]->{location},
        ( $repos[0]->{alias} || '' )
    ) if (@repos);

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db       => $dbw,
        hub      => $ctx->{hub},
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
        print STDERR "$ctx->{hub}: $line";

    };

    my $coro = async {
        eval {
            $dbw->txn(
                sub {
                    my $previous = $dbw->get_max_update_id;
                    my $status   = $client->register;

                    # Catch up on errors
                    undef $stderr_watcher;
                    $stderr->blocking(0);
                    while ( my $line = $stderr->getline ) {
                        print STDERR "$ctx->{hub}: $line";
                    }

                    if ( $status ne 'RepoImported' ) {
                        $error = $status;
                        $dbw->rollback;
                        return $status;
                    }

                    my $current = $dbw->get_max_update_id;
                    my $delta   = $current - $previous;

                    my ($id) = $dbw->xarray(
                        select => 'rl.repo_id',
                        from   => 'repo_locations rl',
                        where  => { 'rl.location' => $ctx->{hub} },
                    );

                    $dbw->xdo(
                        update => 'repos',
                        set    => { alias => $ctx->{alias} },
                        where  => { id => $id },
                    );

                    $dbw->update_repo(
                        {
                            author => $ctx->{user}->{name},
                            email  => $ctx->{user}->{email},
                            message =>
                              "register $ctx->{alias} ($ctx->{hub}) [+$delta]",
                        }
                    );

                    print "Hub registered: $ctx->{alias}\n";
                    return $status;
                }
            );
        };

        $error .= $@ if $@;
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

0.1.0_13 (2014-04-23)

=head1 SYNOPSIS

    bif register HUB [OPTIONS...]

=head1 DESCRIPTION

The C<bif register> command connects to a hub (a remote repository) to
obtain the list of projects hosted there. The project list is stored
locally and is used by the C<import> and C<push> commands when
communicating with the hub.

A hub can have an alias which useable with all of the hub-aware
commands (import,export,push) to save typing the full address.

If C<HUB> is a network address like C<an.organisation@a.provider> then
the default alias will be C<an.organisation>.  If C<hub> is a
filesystem path then the default alias is the path basename.

=head1 ARGUMENTS & OPTIONS

=over

=item HUB

The location of a remote hub.

=item --alias, -a

Override the default alias for the HUB.

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

