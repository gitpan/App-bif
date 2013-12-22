package App::bif::export;
use strict;
use warnings;
use App::bif::Util;
use AnyEvent;
use Bif::Sync::Client;
use Coro;

our $VERSION = '0.1.0';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    $opts = bif_init($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Sync?
    my $db = bif_dbw;

    my @pinfo;
    foreach my $path ( @{ $opts->{path} } ) {
        my $pinfo = $db->get_project($path);

        bif_err( 'ProjectNotFound', 'project not found: %s', $path )
          unless $pinfo;

        $pinfo->{path} = $path;
        $pinfo->{status} = [ 0, 'Not Exported' ];
        push( @pinfo, $pinfo );
    }

    my $hub = $db->hub_info( $opts->{hub} )
      || { location => $opts->{hub} };

    if ( $hub->{location} =~ m!^bif://! ) {
    }
    elsif ( !-d $hub->{location} ) {
        bif_err( 'HubNotFound', 'hub not found: %s', $opts->{hub} );
    }

    $|++;    # no buffering
    my $err;
    my $status;
    my $cv = AE::cv;

    my $client = Bif::Sync::Client->new(
        db       => $db,
        hub      => $hub->{location},
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
        foreach my $pinfo (@pinfo) {
            $status = eval { $client->export_project($pinfo) };

            if ($@) {
                $err = $@;
                last;
            }

            if ( !$status ) {
                $err ||= 'unknown error';
                last;
            }

            print "$pinfo->{path}: $status->[1] [$status->[0]]\n";
            last unless ( $status->[0] == 201 or $status->[0] == 308 );
        }

        # Catch up on errors
        undef $stderr_watcher;
        $stderr->blocking(0);
        while ( my $line = $stderr->getline ) {
            print STDERR 'hub: ' . $line;
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

    bif_err( 'Export', $err ) if $err;
    bif_err( 'Unknown', 'unknown error' ) unless $status;

    if ( $status->[0] == 201 ) {
        return bif_ok('Created');
    }
    elsif ( $status->[0] == 308 ) {
        return bif_ok('Found');
    }
    elsif ( $status->[0] == 409 ) {
        bif_err( 'PathExists', 'hub: project path exists with different uuid' );
    }
    elsif ( $status->[0] == 500 ) {
        bif_err( 'InternalServerError', 'hub: internal server error' );
    }

    bif_err( 'Export', "@$status" );
}

1;
__END__

=head1 NAME

bif-export -  export a project to a remote hub

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif export PATH... HUB [OPTIONS...]

=head1 DESCRIPTION

Export a project to a hub.

=head1 ARGUMENTS

=over

=item PATH

The path of the local project to export.  An error will be raised if a
project with the same path exists at the remote HUB.

=item HUB

The location of a remote hub or a previously defined hub alias.

=back

=head1 OPTIONS

=over

=item --alias

Create an alias for C<HUB> which can be used in future calls to
C<import> or C<export>. Typically this would be the name of the
organisation that owns or manages the hub.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

