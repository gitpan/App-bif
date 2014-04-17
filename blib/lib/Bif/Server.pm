package Bif::Server;
use strict;
use warnings;
use Bif::Mo;
use Coro::Handle;
use JSON;
use Log::Any '$log';
use Role::Basic qw/with/;

our $VERSION = '0.1.0_10';

with 'Bif::Role::Sync';

has debug => ( is => 'rw' );

has db => (
    is       => 'ro',
    required => 1,
);

has rh => ( is => 'rw' );

has wh => ( is => 'rw' );

has json => ( is => 'rw', default => sub { JSON->new->utf8 } );

has on_error => ( is => 'ro', required => 1 );

# Names are reversed, so that the methods make sense from the server's
# point of view.

my %METHODS = (
    EXPORT => {
        project => 'import_project',
    },
    IMPORT => {
        repo    => 'export_repo',
        project => 'sync_project',
    },
    SYNC => {
        repo    => 'sync_repo',
        project => 'sync_project',
    },
    QUIT => {},
);

sub BUILD {
    my $self = shift;
    $self->json->pretty if $self->debug;
}

sub accept {
    my $self = shift;
    $self->rh( Coro::Handle->new_from_fh(*STDIN) );
    $self->wh( Coro::Handle->new_from_fh(*STDOUT) );

    my ( $action, $type, @rest ) = $self->read;

    # TODO a VERSION check

    if ( !$action ) {
        $self->write( 'MissingAction', 'missing [1] action' );
        return;
    }

    if ( !exists $METHODS{$action} ) {
        $self->write( 'InvalidAction', 'Invalid Action: ' . $action );
        return;
    }

    if ( $action eq 'QUIT' ) {
        $self->write( 'QUIT', 'Bye' );
        return;
    }

    if ( !$type ) {
        $self->write( 'MissingType', 'missing [2] type' );
        return;
    }

    my $method = $METHODS{$action}->{$type};

    if ( !$self->can($method) ) {
        $self->write( 'TypeNotImplemented', 'type not implemented: ' . $type );
        return;
    }

    my $response = eval {
        $self->db->txn( sub { $self->$method(@rest) } );
    };

    if ($@) {
        $log->error($@);
        $self->write( 'InternalError', 'Internal Server Error' );
        return;
    }

    return $response;
}

sub export_repo {
    my $self = shift;
    my $db   = $self->db;
    my $id   = shift || $db->get_local_repo_id;

    my ($uuid) = $db->xarray(
        select => 't.uuid',
        from   => 'topics t',
        where  => { 't.id' => $id },
    );

    $self->write( 'EXPORT', 'repo', $uuid );
    return $self->real_export_repo($id);
}

sub sync_repo {
    my $self = shift;
    my $uuid = shift || 'unknown';
    my $hash = shift || 'unknown';

    my $db   = $self->db;
    my $repo = $db->xhash(
        select     => [ 'r.id', 'r.hash' ],
        from       => 'topics t',
        inner_join => 'repos r',
        on         => 'r.id = t.id',
        where => { 't.uuid' => $uuid },
    );

    if ( !$repo ) {
        $self->write( 'RepoNotFound', 'repo uuid not found here' );
        return 'RepoNotFound';
    }
    elsif ( $repo->{hash} eq $hash ) {
        $self->write( 'RepoMatch', 'no changes to exchange' );
        return 'RepoMatch';
    }

    $self->write( 'SYNC', 'repo', $uuid, $repo->{hash} );
    return $self->real_sync_repo( $repo->{id} );
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
    elsif ( !$hash ) {
        $self->write( 'MissingHash', 'hash is required' );
        return 'MissingHash';
    }

    my $pinfo = $self->db->xhash(
        select     => [ 't.id', 'p.hash' ],
        from       => 'topics t',
        inner_join => 'projects p',
        on         => 'p.id = t.id',
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
