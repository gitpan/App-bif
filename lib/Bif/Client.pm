package Bif::Client;
use strict;
use warnings;
use AnyEvent;
use Bif::Mo;
use Coro::Handle;
use JSON;
use Role::Basic qw/with/;
use Sys::Cmd qw/spawn/;

our $VERSION = '0.1.0_20';

with 'Bif::Role::Sync';

has db => (
    is       => 'ro',
    required => 1,
);

has debug => ( is => 'ro' );

has hub => (
    is       => 'ro',
    required => 1,
);

has child => ( is => 'rw' );

has child_watcher => ( is => 'rw' );

has debug_bs => ( is => 'ro' );

has updates_sent => ( is => 'rw', default => 0 );

has updates_recv => ( is => 'rw', default => 0 );

has on_update => (
    is      => 'rw',
    default => sub {
        sub { }
    }
);

has rh => ( is => 'rw' );

has wh => ( is => 'rw' );

has json => ( is => 'rw', default => sub { JSON->new->utf8 } );

has on_error => ( is => 'ro', required => 1 );

sub BUILD {
    my $self = shift;

    if ( $self->hub =~ m!^ssh://(.+)! ) {
        $self->child(
            spawn( 'ssh', $1, 'bifsync', $self->debug_bs ? '--debug' : (), ) );
    }
    else {
        $self->child(
            spawn(
                  'bifsync', $self->debug_bs
                ? '--debug'
                : (), $self->hub
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
        Coro::Handle->new_from_fh( $self->child->stdout, timeout => 30 ) );
    $self->wh(
        Coro::Handle->new_from_fh( $self->child->stdin, timeout => 30 ) );

    $self->json->pretty if $self->debug;
    return;
}

sub register {
    my $self = shift;
    my $info = shift;

    $self->write( 'IMPORT', 'hub' );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'EXPORT' and $type eq 'hub' ) {
        return $self->real_import_hub;
    }
    return $action;
}

sub sync_hub {
    my $self = shift;
    my $id   = shift;

    my $hub = $self->db->xhash(
        select     => [ 'h.hash', 't.uuid' ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        where => { 'h.id' => $id },
    );

    $self->write( 'SYNC', 'hub', $hub->{uuid}, $hub->{hash} );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'SYNC' and $type eq 'hub' ) {
        return $self->real_sync_hub($id);
    }
    elsif ( $action eq 'RepoMatch' ) {
        $self->on_update->('no changes');
    }

    return $action;
}

sub import_project {
    my $self  = shift;
    my $pinfo = shift;

    my ($hash) = $self->db->xarray(
        select => 'p.hash',
        from   => 'projects p',
        where  => { 'p.id' => $pinfo->{id} },
    );

    $self->write( 'SYNC', 'project', $pinfo->{uuid}, $hash );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'SYNC' and $type eq 'project' ) {
        my $result = $self->real_sync_project( $pinfo->{id} );
        if ( $result eq 'ProjectSync' or $result eq 'ProjectMatch' ) {
            $self->db->xdo(
                update => 'projects',
                set    => 'local = 1',
                where  => { id => $pinfo->{id} },
            );
            return 'ProjectImported';
        }
        return $result;
    }
    elsif ( $action eq 'ProjectMatch' ) {
        $self->on_update->('no changes');
        $self->db->xdo(
            update => 'projects',
            set    => 'local = 1',
            where  => { id => $pinfo->{id} },
        );
        return 'ProjectImported';
    }

    $self->write( 'ExpectedSync', 'Expected SYNC' );
    return 'ExpectedSync';
}

sub sync_project {
    my $self = shift;
    my $id   = shift;

    my $project = $self->db->xhash(
        select     => [ 'p.hash', 't.uuid' ],
        from       => 'projects p',
        inner_join => 'topics t',
        on         => 't.id = p.id',
        where => { 'p.id' => $id },
    );

    $self->write( 'SYNC', 'project', $project->{uuid}, $project->{hash} );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'SYNC' and $type eq 'project' ) {
        return $self->real_sync_project($id);
    }
    elsif ( $action eq 'ProjectMatch' ) {
        $self->on_update->('no changes');
    }

    return $action;
}

sub export_project {
    my $self  = shift;
    my $pinfo = shift;

    $self->write( 'EXPORT', 'project', $pinfo->{uuid}, $pinfo->{path} );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'IMPORT' and $type eq 'project' ) {
        return $self->real_export_project( $pinfo->{id} );
    }
    return $action;
}

sub disconnect {
    my $self = shift;
    $self->write('QUIT') if $self->child_watcher;
    $self->child_watcher(undef);

    return unless my $child = $self->child;
    $child->close;
    $child->wait_child;
    $self->child(undef);

    return;
}

1;
