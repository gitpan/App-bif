package Bif::Sync;
use strict;
use warnings;
use Bif::DB::Plugin::Changes;
use Bif::Mo;
use Coro;
use Log::Any '$log';
use JSON;

our $VERSION = '0.1.4';

has changes_dup => (
    is      => 'rw',
    default => 0
);

has changes_sent => (
    is      => 'rw',
    default => 0
);

has changes_torecv => (
    is      => 'rw',
    default => 0
);

has changes_tosend => (
    is      => 'rw',
    default => 0
);

has changes_recv => (
    is      => 'rw',
    default => 0
);

has debug => (
    is      => 'rw',
    default => 0,
);

has db => (
    is       => 'ro',
    required => 1,
);

has hub_id => ( is => 'rw', );

has on_error => ( is => 'ro', required => 1 );

has on_update => (
    is      => 'rw',
    default => sub { },
);

has rh => ( is => 'rw', );

has wh => ( is => 'rw', );

has json => (
    is      => 'rw',
    default => sub { JSON->new->utf8 },
);

has temp_table => (
    is       => 'rw',
    init_arg => undef,
);

sub new_temp_table {
    my $self = shift;
    my $tmp = 'sync_' . $$ . sprintf( "%08x", rand(0xFFFFFFFF) );

    $self->db->do( 'CREATE TEMPORARY TABLE '
          . $tmp . '('
          . 'id INTEGER UNIQUE ON CONFLICT IGNORE,'
          . 'ucount INTEGER'
          . ')' );

    $self->temp_table($tmp);
    return $tmp;
}

sub read {
    my $self = shift;

    my $json = $self->rh->readline("\n\n");

    if ( !defined $json ) {
        $self->on_error->('connection close/timeout');
        $self->write('EOF/Timeout');
        return 'EOF';
    }

    my $msg = eval { $self->json->decode($json) };

    if ($@) {
        $self->on_error->($@);
        $self->write('InvalidEncoding');
        return 'INVALID';
    }
    elsif ( !defined $msg ) {
        $self->on_error->('no message received');
        $self->write('NoMessage');
        return 'INVALID';
    }

    $log->debugf( 'r: %s', $msg );

    return @$msg;
}

sub write {
    my $self = shift;

    $log->debugf( 'w: %s', \@_ );

    return $self->wh->print( $self->json->encode( \@_ ) . "\n\n" );
}

# Let sub classes override if necessary
sub trigger_on_update { }

sub real_send_changesets {
    my $self       = shift;
    my $total      = shift;
    my $statements = shift;

    $self->changes_tosend( $self->changes_tosend + $total );

    my $sth = $self->db->xprepare_changeset_ext(@$statements);
    $sth->execute;

    my $sent = 0;

    while ( my $changeset = $sth->changeset_ext ) {
        return 'SendFailure' unless $self->write( 'CHANGESET', $changeset );
        $sent++;
        $self->changes_sent( $self->changes_sent + 1 );
        $self->trigger_on_update;
    }

    return 'ChangesetCountMismatch' unless $sent == $total;
    return 'SendChangesets';
}

sub send_changesets {
    my $self       = shift;
    my $total      = shift;
    my $statements = shift;

    $self->write( 'TOTAL', $total );
    my $r = $self->real_send_changesets( $total, $statements );
    return $r unless $r eq 'SendChangesets';

    my ( $recv, $count ) = $self->read;
    return 'SendChangesets' if $recv eq 'Recv' and $count == $total;
    return $recv;
}

sub recv_changesets {
    my $self                = shift;
    my $changeset_functions = shift;
    my $db                  = $self->db;

    my ( $action, $total ) = $self->read;
    $total //= '*undef*';

    if ( $action ne 'TOTAL' or $total !~ m/^\d+$/ ) {
        return "expected TOTAL <int> (not $action $total)";
    }

    my $ucount;
    my $i   = $total;
    my $got = 0;

    $self->changes_torecv( $self->changes_torecv + $total );
    $self->trigger_on_update;

    my %import_functions = (
        CHANGESET => {},
        QUIT      => {},
        CANCEL    => {},
    );

    while ( $got < $total ) {
        my ( $action, $changeset ) = $self->read;

        if ( !exists $import_functions{$action} ) {
            return "not implemented: $action";
        }

        return "expected CHANGSET not: $action"
          unless $action eq 'CHANGESET';

        my $i = 0;
        my $uuid;

        foreach my $delta (@$changeset) {
            my $type = delete $delta->{_}
              || return "missing delta type";

            my $func = $changeset_functions->{$type}
              || return "unknown delta type: $type";

            if ( 0 == $i ) {
                $uuid = $delta->{uuid} || return 'missing [0]->{uuid}';

                # For entities in particular we may already have this
                # changeset so ignore it.
                my $id = $db->xval(
                    select => 'c.id',
                    from   => 'changes c',
                    where  => { 'c.uuid' => $uuid },
                );

                if ($id) {
                    $self->changes_dup( $self->changes_dup + 1 );
                    last;
                }
            }
            else {
                $delta->{change_uuid} = $uuid;
            }

            # This should be a savepoint?
            $db->xdo(
                insert_into => $func,
                values      => $delta,
            );

            $i++;
        }

        $db->xdo(
            insert_into => 'func_merge_changes',
            values      => { merge => 1 },
        );

        $got++;
        $self->changes_recv( $self->changes_recv + 1 );
        $self->trigger_on_update;

    }

    $self->write( 'Recv', $got );
    return 'RecvChangesets';
}

sub exchange_changesets {
    my $self                = shift;
    my $send_total          = shift;
    my $send_statements     = shift;
    my $changeset_functions = shift;
    my $db                  = $self->db;

    # Ensure that this goes out before we get properly asynchronous,
    # particularly before recv_changesets() sends out a Recv message.
    $self->write( 'TOTAL', $send_total );

    # Kick off receiving changesets as a separate Coro thread
    my $coro = async {
        select $App::bif::pager->fh if $App::bif::pager;

        $self->recv_changesets($changeset_functions);
    };

    # Now send receiving changesets
    my $send_status =
      $self->real_send_changesets( $send_total, $send_statements );

    # Cancel the $coro?
    return $send_status unless $send_status eq 'SendChangesets';

    # Collect the recv status
    my $recv_status = $coro->join;
    return $recv_status unless $recv_status eq 'RecvChangesets';

    # Only now can we read the sending status
    my ( $recv, $count ) = $self->read;
    return $recv unless $recv eq 'Recv' and $count == $send_total;

    return 'ExchangeChangesets';
}

1;

=head1 NAME

=for bif-doc #perl

Bif::Sync - synchronisation role

