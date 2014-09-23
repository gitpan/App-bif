package Bif::Server;
use strict;
use warnings;
use Bif::Mo;
use Coro::Handle;
use DBIx::ThinSQL qw/sq/;
use JSON;
use Log::Any '$log';
use Role::Basic qw/with/;

our $VERSION = '0.1.0_28';

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

has changes_tosend => ( is => 'rw', default => 0, );

has changes_torecv => ( is => 'rw', default => 0, );

has changes_sent => ( is => 'rw', default => 0, );

has changes_recv => ( is => 'rw', default => 0, );

has on_update => (
    is      => 'rw',
    default => sub {
        sub { }
    }
);

has on_error => ( is => 'ro', required => 1 );

has temp_table => (
    is       => 'rw',
    init_arg => undef,
);

# Names are reversed, so that the methods make sense from the server's
# point of view.

my %METHODS = (
    EXPORT => {
        project => 'import_project',
    },
    IMPORT => {
        hub     => 'export_hub',
        project => 'sync_project',
        self    => 'export_self',
    },
    SYNC => {
        hub      => 'sync_hub',
        projects => 'sync_projects',
    },
    TRANSFER => {
        hub_changes             => 'real_transfer_hub_changes',
        project_related_changes => 'real_transfer_project_related_changes',
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

    $self->temp_table( 'sync_' . sprintf( "%08x", rand(0xFFFFFFFF) ) );

    $self->db->do( "CREATE TEMPORARY TABLE "
          . $self->temp_table . "("
          . "id INTEGER UNIQUE ON CONFLICT IGNORE,"
          . "ucount INTEGER"
          . ")" );

    $self->db->begin_work;

    while (1) {
        my ( $action, $type, @rest ) = $self->read;

        if ( $action eq 'EOF' ) {
            $self->db->rollback;
            return;
        }
        elsif ( $action eq 'INVALID' ) {
            next;
        }
        elsif ( $action eq 'QUIT' ) {
            $self->db->commit;
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

        my $response = eval { $self->$method(@rest) };

        if ($@) {
            $log->error($@);
            $self->write( 'InternalError', 'Internal Server Error',
                $action, $type, @rest );
            $self->db->rollback;
            next;
        }

        if ( $response eq 'EOF' ) {
            return;
        }
        elsif ( $response eq 'INVALID' ) {
            next;
        }
        elsif ( $response eq 'QUIT' ) {
            $self->db->commit;
            $self->write('Bye');
            return;
        }
    }

    $self->db->rollback;
    return;
}

sub export_self {
    my $self = shift;
    my $db   = $self->db;

    my ( $id, $uuid ) = $db->xlist(
        select     => [ 'bif.identity_id', 't.uuid' ],
        from       => 'bifkv bif',
        inner_join => 'topics t',
        on         => 't.id = bif.identity_id',
        where => { 'bif.key' => 'self' },
    );

    if ( !$uuid ) {
        $self->write( 'SelfNotFound', 'self identity not found here' );
        return 'SelfNotFound';
    }

    $self->write( 'EXPORT', 'identity', $uuid );
    return $self->real_export_identity($id);
}

sub export_hub {
    my $self = shift;
    my $db   = $self->db;
    my $id   = shift || $db->get_local_hub_id;

    my $uuid = $db->xval(
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
    my $hub = $db->xhashref(
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

    my $local = $self->db->xhashref(
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
    my $status = $self->real_import_project($uuid);

    $self->db->xdo(
        update => 'projects',
        set    => 'local = 1',
        where  => {
            id => sq(
                select => 't.id',
                from   => 'topics t',
                where  => { 't.uuid' => $uuid, },
            ),
        },
    );

    return $status;
}

sub sync_projects {
    my $self = shift;
    my @ids;

    foreach my $pair (@_) {
        my ( $uuid, $hash ) = @$pair;

        if ( !$uuid ) {
            $self->write( 'MissingUUID', 'uuid is required' );
            return 'MissingUUID';
        }
        elsif ( !defined $hash ) {
            $self->write( 'MissingHash', 'hash is required' );
            return 'MissingHash';
        }

        my $pinfo = $self->db->xhashref(
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

        push( @ids, $pinfo->{id} );

        #        if ( $pinfo->{hash} eq $hash ) {
        #            $self->write( 'ProjectMatch', $uuid, $pinfo->{hash} );
        #            return 'ProjectMatch';
        #        }
    }

    $self->write( 'SYNC', 'projects' );

    foreach my $id (@ids) {
        my $status = $self->real_sync_project( $id, \@ids );
        return $status unless $status eq 'ProjectSync';
    }

    return 'ProjectSync';
}

sub disconnect {
    my $self = shift;
    $log->info('disconnect');
    $self->rh->close;
    $self->wh->close;
    return;
}

1;
