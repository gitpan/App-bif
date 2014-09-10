package Bif::Client;
use strict;
use warnings;
use AnyEvent;
use Bif::Mo;
use Coro::Handle;
use DBIx::ThinSQL qw/sq/;
use JSON;
use Role::Basic qw/with/;
use Sys::Cmd qw/spawn/;

our $VERSION = '0.1.0_27';

with 'Bif::Role::Sync';

has db => (
    is       => 'ro',
    required => 1,
);

has name => (
    is       => 'ro',
    required => 1,
);

has debug => ( is => 'ro' );

has location => ( is => 'ro', );

has hub_id => (
    is      => 'rw',
    default => sub {
        my $self   = shift;
        my $hub_id = $self->db->xval(
            select => 'hr.hub_id',
            from   => 'hub_repos hr',
            where  => { 'hr.location' => $self->location },
        );
        return $hub_id;
    },
);

has child => ( is => 'rw' );

has child_watcher => ( is => 'rw' );

has stderr_watcher => ( is => 'rw' );

has debug_bifsync => ( is => 'ro' );

has updates_tosend => ( is => 'rw', default => 0 );

has updates_torecv => ( is => 'rw', default => 0 );

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

has temp_table => (
    is       => 'rw',
    init_arg => undef,
    default  => sub {
        my $self = shift;
        my $tmp = 'sync_' . sprintf( "%08x", rand(0xFFFFFFFF) );

        $self->db->do( "CREATE TEMPORARY TABLE "
              . $tmp . "("
              . "id INTEGER UNIQUE ON CONFLICT IGNORE,"
              . "ucount INTEGER"
              . ")" );

        return $tmp;
    },
);

sub BUILD {
    my $self = shift;

    if ( $self->location =~ m!^ssh://(.+)! ) {
        $self->child(
            spawn( 'ssh', $1, 'bifsync', $self->debug_bifsync ? '--debug' : (),
            )
        );
    }
    else {
        $self->child(
            spawn(
                  'bifsync', $self->debug_bifsync
                ? '--debug'
                : (),
                $self->location
            )
        );
    }

    $self->child_watcher(
        AE::child $self->child->pid,
        sub {
            $self->on_error->('child process ended unexpectedly');
        }
    );

    my $stderr = $self->child->stderr;
    my $name   = $self->name;

    $self->stderr_watcher(
        AE::io $stderr,
        0,
        sub {
            my $line = $stderr->getline;
            if ( !defined $line ) {
                $self->stderr_watcher(undef);
                return;
            }
            print STDERR "$name: $line";
        }
    );

    $self->rh(
        Coro::Handle->new_from_fh( $self->child->stdout, timeout => 30 ) );
    $self->wh(
        Coro::Handle->new_from_fh( $self->child->stdin, timeout => 30 ) );

    $self->json->pretty if $self->debug;
    return;
}

sub bootstrap_identity {
    my $self = shift;

    $self->write( 'IMPORT', 'self' );

    my ( $action, $type, $uuid ) = $self->read;
    return $action
      unless ( $action eq 'EXPORT' and $type eq 'identity', and $uuid );

    my $status = $self->real_import_identity;
    return $status unless $status eq 'IdentityImported';

    my $dbw = $self->db;
    my ( $iid, $uid ) = $dbw->xlist(
        select     => [ 't.id', 't.first_update_id' ],
        from       => 'topics t',
        inner_join => 'identities i',
        on         => 'i.id = t.id',
        where => { 't.uuid' => $uuid, },
    );

    return 'IdentityNotImported' unless $iid;

    $dbw->xdo(
        insert_into => 'bifkv',
        values      => { key => 'self', identity_id => $iid },
    );

    $dbw->xdo(
        update => 'updates',
        set    => { identity_id => $iid },
        where  => { id => $uid },
    );

    return $status;
}

sub pull_hub {
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

    my $hub = $self->db->xhashref(
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

sub transfer_hub_updates {
    my $self = shift;

    $self->write( 'TRANSFER', 'hub_updates' );
    return $self->real_transfer_hub_updates;
}

sub import_project {
    my $self  = shift;
    my $pinfo = shift;

    my $hash = $self->db->xval(
        select => 'hrp.hash',
        from   => 'hub_related_projects hrp',
        where  => {
            'hrp.hub_id'     => $self->hub_id,
            'hrp.project_id' => $pinfo->{id},
        },
    );

    $self->write( 'SYNC', 'project', $pinfo->{uuid}, $hash );

    my ( $action, $type ) = $self->read;
    if ( $action eq 'SYNC' and $type eq 'project' ) {
        my $result = $self->real_sync_project( $pinfo->{id} );
        if ( $result eq 'ProjectSync' or $result eq 'ProjectMatch' ) {
            my $status = $self->transfer_project_related_updates;
            return $status unless $status eq 'TransferProjectRelatedUpdates';

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

sub sync_projects {
    my $self = shift;

    my @projects = $self->db->xarrayrefs(
        select     => [ 't.uuid', 'hrp.hash', 't.id' ],
        from       => 'projects p',
        inner_join => 'hub_related_projects hrp',
        on         => 'hrp.hub_id = p.hub_id AND hrp.project_id = p.id',
        inner_join => 'topics t',
        on         => 't.id = p.id',
        where      => {
            'p.hub_id' => $self->hub_id,
            'p.local'  => 1,
        },
        order_by => 't.uuid',
    );

    my @ids = map { pop @$_ } @projects;
    $self->write( 'SYNC', 'projects', @projects );

    my ( $action, $type ) = $self->read;
    return $action unless ( $action eq 'SYNC' and $type eq 'projects' );

    foreach my $id (@ids) {
        my $status = $self->real_sync_project( $id, \@ids );
        return $status unless $status eq 'ProjectSync';
    }

    return 'ProjectSync';
}

sub transfer_project_related_updates {
    my $self = shift;

    $self->write( 'TRANSFER', 'project_related_updates' );
    return $self->real_transfer_project_related_updates;
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

sub cleanup_errors {
    my $self = shift;
    return unless $self->stderr_watcher || $self->child;

    my $name = $self->name;

    $self->stderr_watcher(undef);
    my $stderr = $self->child->stderr;
    $stderr->blocking(0);

    while ( my $line = $stderr->getline ) {
        print STDERR "$name: $line";
    }

    return;
}

sub disconnect {
    my $self = shift;
    $self->cleanup_errors;

    $self->write('QUIT') if $self->child_watcher;
    $self->child_watcher(undef);

    return unless my $child = $self->child;
    $child->close;
    $child->wait_child;
    $self->child(undef);

    return;
}

sub DESTROY {
    my $self = shift;
    $self->disconnect;
}

1;

__END__

=head1 NAME

Bif::Client - client for communication with a bif hub

=head1 VERSION

0.1.0_27 (2014-09-10)

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
        $client->pull_hub;
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

=item debug_bifsync

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


=item pull_hub


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

