package App::bif::import;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0';

sub run {
    my $ctx = shift;
    $ctx->{no_pager}++;    # causes problems with something in Coro?
    $ctx = App::bif::Context->new($ctx);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $db = $ctx->dbw;

    my @locations = $db->get_repo_locations( $ctx->{hub} );
    $ctx->err( 'HubNotFound', 'hub not found: %s', $ctx->{hub} )
      unless @locations;

    my $hub = $locations[0];

    my @pinfo;
    foreach my $path ( @{ $ctx->{path} } ) {
        my $pinfo = $db->get_project( $path . '@' . $hub->{alias} );

        return $ctx->err( 'ProjectNotFound', 'project not found: %s', $path )
          unless $pinfo;

        if ( $pinfo->{local} ) {
            print "Project already imported: $pinfo->{path}\n";
            next;
        }

        push( @pinfo, $pinfo );
    }

    return $ctx->ok('Import')
      unless @pinfo;

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db       => $db,
        hub      => $hub->{location},
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
            $db->txn(
                sub {
                    $db->update_repo(
                        {
                            author => $ctx->{user}->{name},
                            email  => $ctx->{user}->{email},

            #                            related_update_id => $ctx->{update_id},
                            message =>
                              "import @{$ctx->{path}} $hub->{location}",
                        }
                    );

                    foreach my $pinfo (@pinfo) {
                        my $status = $client->import_project($pinfo);

                        if ( $status eq 'ProjectImported' ) {
                            print "Project imported: $pinfo->{path}\n";
                        }
                        else {
                            $db->rollback;
                            $error = $status;
                            last;
                        }

                    }

                    # Catch up on errors
                    undef $stderr_watcher;
                    $stderr->blocking(0);
                    while ( my $line = $stderr->getline ) {
                        print STDERR "$hub->{alias}: $line";
                    }

                    return;
                }
            );
        };

        $error .= $@ if $@;
        $client->disconnect;
        return $cv->send( !$error );
    };

    return $ctx->ok('Import') if $cv->recv;
    return $ctx->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

bif-import -  import projects from a remote hub

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif import PATH... HUB

=head1 DESCRIPTION

Import projects from a hub.

=head1 ARGUMENTS

=over

=item PATHS...

The path of the remote project to import.

=item HUB

The alias of a previously registered hub.

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

