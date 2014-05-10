package Bif::Client;
use strict;
use warnings;
use AnyEvent;
use Bif::Mo;
use Coro::Handle;
use JSON;
use Role::Basic qw/with/;
use Sys::Cmd qw/spawn/;

our $VERSION = '0.1.0_22';

with 'Bif::Role::Sync';

has db => (
    is       => 'ro',
    required => 1,
);

has debug => ( is => 'ro' );

has location => ( is => 'ro', );

has hub_id => ( is => 'rw', );

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

    if ( $self->location =~ m!^ssh://(.+)! ) {
        $self->child(
            spawn( 'ssh', $1, 'bifsync', $self->debug_bs ? '--debug' : (), ) );
    }
    else {
        $self->child(
            spawn(
                  'bifsync', $self->debug_bs
                ? '--debug'
                : (),
                $self->location
            )
        );
    }

    $self->hub_id(
        $self->db->xarray(
            select => 'hl.hub_id',
            from   => 'hub_locations hl',
            where  => { 'hl.location' => $self->location },
        )
    );

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
    my $id = shift || die 'sync_hub($id)';

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
        select     => [ 'hrp.hash', 't.uuid' ],
        from       => 'hub_related_projects hrp',
        inner_join => 'topics t',
        on    => { 't.id'           => $id, },
        where => { 'hrp.project_id' => $id, 'hrp.hub_id' => $self->hub_id, },
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

__END__

=head1 NAME

Bif::Client - client for communication with a bif hub

=head1 VERSION

0.1.0_22 (2014-05-10)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use AnyEvent;
    use App::bif::Context;
    use Bif::Client;

    my $ctx = App::bif::Context->new( {} );
    my $client = Bif::Client->new(
        db       => $ctx->dbw,
        location => $LOCATION,
    );

    # Bif::Client is a Coro::Handle user so you want
    # to do things inside a coroutine
    async {
        $client->register;
    };

    AnyEvent->condvar->recv;

=head1 DESCRIPTION

B<Bif::Client> is a class for communicating with a bif hub.

=head1 CONSTRUCTOR

=over 4

=item Bif::Client->new( db => $dbh, hub => $location )

=back

=head1 ATTRIBUTES

=over 4

=item db

=item debug

=item child

=item child_watcher

=item debug_bs

=item hub_id

=item location

=item updates_sent

=item updates_recv

=item on_update

=item rh

=item wh

=item json

=item on_error

=back

=head1 METHODS

=over 4


=item register


=item sync_hub($hub_id)

Compares the C<hub_related_updates> table in the local repository
against the same table on the hub and exchanges updates until they are
the same. This method only results in project-only updates.

=item import_project


=item sync_project


=item export_project


=item disconnect

=back

=head1 SEE ALSO

L<Bif::Server>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

