package App::bif::sync;
use strict;
use warnings;
use App::bif::Util;
use Log::Any qw/$log/;
use Path::Class;

our $VERSION = '0.1.0';

# usage: bif [options] sync [ID] [LOCATION]
#
#     --debug,  -d     define modules to debug
#     --help,   -h     print this help message and exit
#
#     ID               the ID or project path to synchronise
#     LOCATION         hub repository address or alias

my $client;
my $type;
my $name;

sub _connect_hub {
    my $location = shift;

    $client->on_connect(
        sub {
            print "connected to: $location\n";
            $client->cv->send(1);
        }
    );

    $client->connect($location)
      || bif_err( 'could not connect: ' . $location );
}

sub _setup {

    if ( -t STDOUT and !$log->is_debug ) {
        $client->on_comparing_update(
            sub {
                line_print(
                    sprintf(
                        '%s %s: comparing: %s',
                        $type, $name, $client->comparing
                    )
                );
            }
        );

        my $show_update = sub {
            line_print(
                sprintf(
                    '%s %s: sent: %d received: %d',
                    $type,                 $name,
                    $client->sent_updates, $client->recv_updates
                )
            );
        };

        $client->on_send_update($show_update);

        $client->on_recv_update($show_update);
    }

}

sub _teardown {
    if ( $client->sent_updates or $client->recv_updates ) {
        line_print(
            sprintf(
                "%s %s: sent: %d received: %d\n",
                $type, $name, $client->sent_updates, $client->recv_updates
            )
        );
    }
    else {
        line_print("$type $name: no changes\n");
    }
}

sub _real_run {
    my $db       = shift;
    my $location = shift;
    my $id       = shift;

    if ($id) {

        $type = opts_thread( { thread => $id } );
        if ( $type eq 'project' ) {
            $name = $id;
            _setup();
            _connect_hub($location);
            $client->sync_project( { id => $id } )
              || bif_err('sync failed');
            _teardown();
            $client->disconnect;
        }
        else {
            not_implemented('sync based on ID');
        }
        return;
    }
    elsif ($location) {

        my @topics = $db->location2topics($location);
        if ( !@topics ) {
            return;
        }

        _connect_hub($location);

        foreach my $thread (@topics) {

            $type = $thread->kind;
            if ( $type eq 'project' ) {
                $name = $thread->path;
                _setup();
                $client->sync_project( { id => $thread->id } )
                  || bif_err('sync failed');
                _teardown();
            }
            else {
                $name = $thread->id;
                _setup();
                print "type $type doesn't work\n";
            }
        }

        $client->disconnect;
        return;
    }
}

sub run {
    my $opts = shift;
    set_log($opts);

    my $db = find_db($opts);

    $client = $db->client;

    if ( $opts->{location} ) {
        opts_thread($opts);
        check_hub($opts);
        _real_run( $db, $opts->{location}, $opts->{id} );
    }
    elsif ( $opts->{thread} ) {
        opts_thread($opts);

        foreach my $location ( $db->hub_locations( $opts->{id} ) ) {
            _real_run( $db, $location, $opts->{id} );
        }
    }
    else {
        foreach my $location ( $db->hub_locations ) {
            _real_run( $db, $location );
        }
    }

}

1;
__END__

=head1 NAME

bif-sync - exchange updates with a hub

=head1 DESCRIPTION

See L<bif>(1) for details.

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

