package Bif::Client;
use strict;
use warnings;
use AnyEvent;
use Bif::Mo;
use Coro::Handle;
use JSON;
use Role::Basic qw/with/;
use Sys::Cmd qw/spawn/;

our $VERSION = '0.1.0';

with 'Bif::Role::Sync';

has db => (
    is       => 'ro',
    required => 1,
);

has hub => (
    is       => 'ro',
    required => 1,
);

has child => ( is => 'rw' );

has child_watcher => ( is => 'rw' );

has on_update => ( is => 'rw' );

has status => ( is => 'rw', default => sub { [ 0, 'Undefined' ] } );

has rh => ( is => 'rw' );

has wh => ( is => 'rw' );

has json => ( is => 'rw', default => sub { JSON->new->utf8 } );

has on_error => ( is => 'ro', required => 1 );

sub BUILD {
    my $self = shift;

    if ( $self->hub =~ m!^ssh://(.+?):(.+)! ) {
        $self->child( spawn( 'ssh', $1, 'bifsync', $2 ) );
    }
    else {
        $self->child( spawn( 'bifsync', $self->hub ) );
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

sub register {
    my $self = shift;
    my $info = shift;

    $self->write( [ 'IMPORT', 'repo' ] );

    my $msg = $self->read;
    if ( $msg->[0] eq 'EXPORT' and $msg->[1] eq 'repo' ) {
        return $self->real_import_repo;
    }
    return $msg->[0];
}

sub sync_repo {
    my $self = shift;
    my $id   = shift;

    my $repo = $self->db->xhash(
        select     => [ 'r.hash', 't.uuid' ],
        from       => 'repos r',
        inner_join => 'topics t',
        on         => 't.id = r.id',
        where => { 'r.id' => $id },
    );

    $self->write( [ 'SYNC', 'repo', $repo->{uuid}, $repo->{hash} ] );

    my $msg = $self->read;
    if ( $msg->[0] eq 'SYNC' and $msg->[1] eq 'repo' ) {
        return $self->real_sync_repo( $repo->{id} );
    }

    return $msg->[0];
}

sub export_project {
    my $self  = shift;
    my $pinfo = shift;

    $self->write( [ 'EXPORT', 'project', $pinfo->{uuid}, $pinfo->{path} ] );

    my $msg = $self->read;
    if ( $msg->[0] eq 'IMPORT' and $msg->[1] eq 'project' ) {
        return $self->real_export_project( $pinfo->{id} );
    }
    return $msg->[0];
}

sub import_project {
    my $self  = shift;
    my $pinfo = shift;

    my ($hash) = $self->db->xarray(
        select => 'p.hash',
        from   => 'projects p',
        where  => { 'p.id' => $pinfo->{id} },
    );

    $self->write( [ 'SYNC', 'project', $pinfo->{uuid}, $hash ] );

    my $msg = $self->read;
    if ( $msg->[0] eq 'SYNC' and $msg->[1] eq 'project' ) {
        my $result = $self->real_sync_project( $pinfo->{id} );
        if ( $result eq 'ProjectImported' or $result eq 'ProjectMatch' ) {
            $self->db->xdo(
                update => 'projects',
                set    => 'local = 1',
                where  => { id => $pinfo->{id} },
            );
            return 'ProjectImported';
        }
        return $result;
    }
    elsif ( $msg->[0] eq 'ProjectMatch' ) {
        $self->db->xdo(
            update => 'projects',
            set    => 'local = 1',
            where  => { id => $pinfo->{id} },
        );
        return 'ProjectImported';
    }

    $self->write( [ 'ExpectedSync', 'Expected SYNC' ] );
    return 'ExpectedSync';
}

sub disconnect {
    my $self = shift;
    $self->write( ['QUIT'] ) if $self->child_watcher;
    $self->child_watcher(undef);

    return unless my $child = $self->child;
    $child->close;
    $child->wait_child;
    $self->child(undef);

    return;
}

1;
