package App::bifsync;
use strict;
use warnings;
use App::bif;
use AnyEvent;
use Bif::DBW;
use Bif::Mo;
use Bif::Sync::Server;
use Coro;
use Log::Any '$log';
use Log::Any::Adapter;
use Log::Any::Plugin;
use OptArgs;
use Path::Tiny;

our $VERSION = '0.1.4';

arg directory => (
    isa     => 'Str',
    comment => 'location of bif repository',
    default => 'default.bif',
);

opt debug => (
    isa     => 'Bool',
    comment => 'add debugging statements to stderr',
);

# class
has opts => (
    is       => 'ro',
    required => 1,
);

sub run {
    my $self = shift;
    my $opts = $self->opts;

    # no buffering
    $|++;
    my $tmp = select STDERR;
    $|++;
    select $tmp;

    my $f      = 'db.sqlite3';
    my $dir    = path( $opts->{directory} );
    my $sqlite = $dir->child($f);

    die Bif::Error->new( $opts, 'RepoNotFound', "directory not found: $dir\n" )
      unless -e $dir;

    if ( !-f $sqlite ) {
        $log->error( 'file not found: ' . $sqlite );
        die Bif::Error->new( $opts, 'FileNotFound',
            "file not found: $sqlite\n" );
    }
    if ( $opts->{debug} ) {
        Log::Any::Adapter->set('Stderr');
    }
    else {
        # TODO use Syslog (when development is stable)
        Log::Any::Adapter->set('Stderr');
        Log::Any::Plugin->add( 'Levels', level => 'warning' );
    }

    $log->debug( 'db: ' . $sqlite );

    my $err;
    my $cv = AnyEvent->condvar;
    my $db = Bif::DBW->connect( 'dbi:SQLite:dbname=' . $sqlite,
        undef, undef, undef, $opts->{debug} );

    my $server = Bif::Sync::Server->new(
        db       => $db,
        debug    => $opts->{debug},
        on_error => sub {
            $err = shift;
        },
    );

    my $coro = async {
        $server->run;
        $server->disconnect;
        $cv->send;
    };

    my $sig = AE::signal 'INT', sub {
        $coro->cancel;
        $server->disconnect('INT');
        $cv->send;
    };

    $cv->recv;

    return Bif::Error->new( $opts, 'Bifsync', $err ) if $err;
    return Bif::OK->new( $opts, 'BifSync' );
}

1;
__END__

=head1 NAME

App::bifsync - Bifax synchronisation server

=head1 DESCRIPTION

See L<bifsync>(1) for details.

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

