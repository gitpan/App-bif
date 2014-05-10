package Bif::Server;
use strict;
use warnings;
use Bif::Mo;
use Coro::Handle;
use JSON;
use Log::Any '$log';
use Role::Basic qw/with/;

our $VERSION = '0.1.0_22';

with 'Bif::Role::Sync';

has debug => ( is => 'rw' );

has db => (
    is       => 'ro',
    required => 1,
);

has hub_id => ( is => 'rw', );

has rh => ( is => 'rw' );

has wh => ( is => 'rw' );

has json => ( is => 'rw', default => sub { JSON->new->utf8 } );

has updates_sent => ( is => 'rw' );

has updates_recv => ( is => 'rw' );

has on_update => (
    is      => 'rw',
    default => sub {
        sub { }
    }
);

has on_error => ( is => 'ro', required => 1 );

# Names are reversed, so that the methods make sense from the server's
# point of view.

my %METHODS = (
    EXPORT => {
        project => 'import_project',
    },
    IMPORT => {
        hub     => 'export_hub',
        project => 'sync_project',
    },
    SYNC => {
        hub     => 'sync_hub',
        project => 'sync_project',
    },
    QUIT => {},
);

sub BUILD {
    my $self = shift;
    $self->json->pretty if $self->debug;
    $self->hub_id( $self->db->get_local_hub_id );
}

sub run {
    my $self = shift;
    $self->rh( Coro::Handle->new_from_fh( *STDIN, timeout => 30 ) );
    $self->wh( Coro::Handle->new_from_fh(*STDOUT) );

    while (1) {
        my ( $action, $type, @rest ) = $self->read;

        if ( $action eq 'EOF' ) {
            return;
        }
        elsif ( $action eq 'INVALID' ) {
            next;
        }
        elsif ( $action eq 'QUIT' ) {
            $self->write('Bye');
            return;
        }

        # TODO a VERSION check

        if ( !exists $METHODS{$action} ) {
            $self->write( 'InvalidAction', 'Invalid Action: ' . $action );
            next;
        }

        if ( !$type ) {
            $self->write( 'MissingType', 'missing [2] type' );
            next;
        }

        my $method = $METHODS{$action}->{$type};

        if ( !$self->can($method) ) {
            $self->write( 'TypeNotImplemented',
                'type not implemented: ' . $type );
            next;
        }

        my $response = eval {
            $self->db->txn( sub { $self->$method(@rest) } );
        };

        if ($@) {
            $log->error($@);
            $self->write( 'InternalError', 'Internal Server Error' );
            next;
        }

        if ( $response eq 'EOF' ) {
            return;
        }
        elsif ( $response eq 'INVALID' ) {
            next;
        }
        elsif ( $response eq 'QUIT' ) {
            $self->write('Bye');
            return;
        }
    }
}

sub export_hub {
    my $self = shift;
    my $db   = $self->db;
    my $id   = shift || $db->get_local_hub_id;

    my ($uuid) = $db->xarray(
        select => 't.uuid',
        from   => 'topics t',
        where  => { 't.id' => $id },
    );

    $self->write( 'EXPORT', 'hub', $uuid );
    return $self->real_export_hub($id);
}

sub sync_hub {
    my $self = shift;
    my $uuid = shift || 'unknown';
    my $hash = shift || 'unknown';

    my $db  = $self->db;
    my $hub = $db->xhash(
        select     => [ 'h.id', 'h.hash' ],
        from       => 'topics t',
        inner_join => 'hubs h',
        on         => 'h.id = t.id',
        where => { 't.uuid' => $uuid },
    );

    if ( !$hub ) {
        $self->write( 'RepoNotFound', 'hub uuid not found here' );
        return 'RepoNotFound';
    }
    elsif ( $hub->{hash} eq $hash ) {
        $self->write( 'RepoMatch', 'no changes to exchange' );
        return 'RepoMatch';
    }

    $self->write( 'SYNC', 'hub', $uuid, $hub->{hash} );
    return $self->real_sync_hub( $hub->{id} );
}

sub import_project {
    my $self = shift;
    my $uuid = shift;
    my $path = shift;

    if ( !$uuid ) {
        $self->write( 'MissingUUID', 'uuid is required' );
        return;
    }
    elsif ( !$path ) {
        $self->write( 'MissingPath', 'path is required' );
        return;
    }

    my $local = $self->db->xhash(
        select    => [ 'p.id AS id', 't2.uuid AS other_uuid', ],
        from      => '(select 1,2)',
        left_join => 'topics t',
        on        => { 't.uuid'  => $uuid },
        left_join => 'projects p',
        on        => 'p.id = t.id',
        left_join => 'projects AS p2',
        on        => { 'p2.path' => $path },
        left_join => 'topics AS t2',
        on        => 't2.id = p2.id',
        limit     => 1,
    );

    if ( $local->{id} ) {
        $self->write( 'ProjectFound', 'project exists' );
        return 'ProjectFound';
    }
    elsif ( $local->{other_uuid} ) {
        $self->write( 'PathExists', 'path is ' . $local->{other_uuid} );
        return 'PathExists';
    }

    $self->write( 'IMPORT', 'project', $uuid );
    return $self->real_import_project($uuid);
}

sub sync_project {
    my $self = shift;
    my $uuid = shift;
    my $hash = shift;

    if ( !$uuid ) {
        $self->write( 'MissingUUID', 'uuid is required' );
        return 'MissingUUID';
    }
    elsif ( !defined $hash ) {
        $self->write( 'MissingHash', 'hash is required' );
        return 'MissingHash';
    }

    my $pinfo = $self->db->xhash(
        select     => [ 't.id', 'hrp.hash' ],
        from       => 'topics t',
        inner_join => 'hub_related_projects hrp',
        on         => {
            'hrp.project_id' => \'t.id',
            'hrp.hub_id'     => $self->hub_id,
        },
        where => { 't.uuid' => $uuid },
    );

    if ( !$pinfo ) {
        $self->write( 'ProjectNotFound', 'project not found: ' . $uuid );
        return 'ProjectNotFound';
    }

    if ( $pinfo->{hash} eq $hash ) {
        $self->write( 'ProjectMatch', $uuid, $pinfo->{hash} );
        return 'ProjectMatch';
    }
    $self->write( 'SYNC', 'project', $uuid, $pinfo->{hash} );
    return $self->real_sync_project( $pinfo->{id} );
}

sub disconnect {
    my $self = shift;
    $log->info('disconnect');
    $self->rh->close;
    $self->wh->close;
    return;
}

1;
