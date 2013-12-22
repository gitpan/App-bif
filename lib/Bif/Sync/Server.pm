package Bif::Sync::Server;
use strict;
use warnings;
use Bif::Mo qw/is build/;
use Coro::Handle;
use Log::Any '$log';

our $VERSION = '0.1.0';

extends 'Bif::Sync';

has debug => ( is => 'rw' );

# Yes, these names are reversed so that from *our* point of view the
# method names are correct.

my %METHODS = (
    EXPORT => { project => 'import_project' },
    IMPORT => { project => 'export_project' },
    SYNC   => { project => 'sync_project' },
    QUIT   => {},
);

sub BUILD {
    my $self = shift;
}

sub accept {
    my $self = shift;
    $self->rh( Coro::Handle->new_from_fh(*STDIN) );
    $self->wh( Coro::Handle->new_from_fh(*STDOUT) );

    my $msg = $self->read;
    if ( !$msg || !defined $msg->[0] || !defined $msg->[1] ) {
        $self->write( [ 400, 'Bad syntax' ] );
        return;
    }

    # TODO a VERSION check with $msg->[0]

    if ( !exists $METHODS{ $msg->[1] } ) {
        $self->write( [ 400, 'Bad Method', $msg->[1] ] );
        return;
    }

    if ( $msg->[1] eq 'QUIT' ) {
        $self->write( [ 999, 'Bye' ] );
        return;
    }

    my $method = $METHODS{ $msg->[1] }->{ $msg->[2] };

    if ( !$self->can($method) ) {
        $self->write( [ 501, 'Not Implemented' ] );
        return;
    }

    my $response = eval { $self->$method($msg) };

    if ($@) {
        $log->error($@);
        $self->write( [ 500, 'Internal Server Error' ] );
        return;
    }

    return $response;
}

sub disconnect {
    my $self = shift;
    $log->info('disconnect');
    $self->rh->close;
    $self->wh->close;
    return;
}

1;
