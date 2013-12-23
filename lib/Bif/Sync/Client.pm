package Bif::Sync::Client;
use strict;
use warnings;
use AnyEvent;
use Bif::Mo qw/is required build default/;
use Coro::Handle;
use Sys::Cmd qw/spawn/;

our $VERSION = '0.1.0';

extends 'Bif::Sync';

has hub => (
    is       => 'ro',
    required => 1,
);

has child => ( is => 'rw' );

has child_watcher => ( is => 'rw' );

has on_update => ( is => 'rw' );

has status => ( is => 'rw', default => sub { [ 0, 'Undefined' ] } );

sub BUILD {
    my $self = shift;

    if ( $self->hub =~ m!^ssh://(.+?):(.+)! ) {
        $self->child( spawn( 'ssh', $1, 'bifsync', $2 ) );
    }
    else {
        $self->child(
            spawn(
                sub {
                    require OptArgs;
                    OptArgs::dispatch( 'run', 'App::bifsync', $self->hub );
                }
            )
        );
    }

    $self->child_watcher(
        AE::child $self->child->pid,
        sub {
            $self->on_error->('child process ended unexpectedly');
        }
    );

    $self->rh(
        Coro::Handle->new_from_fh( $self->child->stdout, timeout => 5 ) );
    $self->wh( Coro::Handle->new_from_fh( $self->child->stdin, timeout => 5 ) );
    return;
}

sub disconnect {
    my $self = shift;
    $self->write( [ $VERSION, 'QUIT' ] ) if $self->child_watcher;
    $self->child_watcher(undef);

    return unless my $child = $self->child;
    $child->close;
    $child->wait_child;
    $self->child(undef);

    return;
}

1;
