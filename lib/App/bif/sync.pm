package App::bif::sync;
use strict;
use warnings;
use parent 'App::bif::Context';
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0_27';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $self = __PACKAGE__->new($opts);
    my $dbw  = $self->dbw;

    if ( $opts->{hub} ) {
        foreach my $name ( @{ $opts->{hub} } ) {
            my @rl = $dbw->get_hub_repos($name);
            $self->err( 'HubNotFound', 'hub not found: ' . $name )
              unless @rl;
        }
    }

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my @hubs = $dbw->xhashrefs(
        select     => [ 'h.id', 'h.name', 'hr.location', 't.uuid' ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        inner_join => 'hub_repos hr',
        on    => 'hr.id = h.default_repo_id',
        where => {
            'h.local' => undef,
            $opts->{hub} ? ( 'h.name' => $opts->{hub} ) : (),
        },
        order_by => 'h.name',
    );

    return $self->err( 'SyncNone', 'no (matching) hubs found' )
      unless @hubs;

    $|++;    # no buffering

    foreach my $hub (@hubs) {
        my $error;
        my $cv = AE::cv;
        $self->lprint("$hub->{name}: connecting...");

        my $client = Bif::Client->new(
            name          => $hub->{name},
            db            => $dbw,
            location      => $hub->{location},
            debug         => $self->{debug},
            debug_bifsync => $self->{debug_bifsync},
            on_error      => sub {
                $error = shift;
                $cv->send;
            },
        );

        my $coro = async {
            eval {
                $dbw->txn(
                    sub {
                        my $uid = $self->new_update(
                            message =>
                              "sync hub $hub->{name} via $hub->{location}"
                              . $self->{message},
                            action => "sync hub $hub->{name}",
                        );

                        $dbw->xdo(
                            insert_or_replace_into => 'bifkv',
                            values                 => {
                                key       => 'last_sync',
                                update_id => $uid,
                            },
                        );

                        $client->on_update(
                            sub {
                                $self->lprint("$hub->{name}: $_[0]");
                            }
                        );

                        my $previous = $dbw->get_max_update_id;
                        my $status   = $client->sync_hub( $hub->{id} );

                        unless ( $status eq 'RepoMatch'
                            or $status eq 'RepoSync' )
                        {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return;

                        }

                        if ( $status eq 'RepoSync' ) {
                            $status = $client->transfer_hub_updates;
                            if ( $status ne 'TransferHubUpdates' ) {
                                $dbw->rollback;
                                $error = "unexpected status received: $status";
                                return;
                            }
                        }

                        $status = $client->sync_projects;

                        unless ( $status eq 'ProjectSync' ) {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return;
                        }

                        $status = $client->transfer_project_related_updates;

                        if ( $status ne 'TransferProjectRelatedUpdates' ) {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return;
                        }
                        print "\n";

                        my $current = $dbw->get_max_update_id;
                        my $delta   = $current - $previous;

                        return;
                    }
                );
            };

            if ($@) {
                $error .= $@;
                print "\n";
            }

            $client->disconnect;
            return $cv->send( !$error );
        };

        if ( $cv->recv ) {
            next;
        }

        return $self->err( 'Unknown', $error );

    }

    # TODO make this dependent on how many updates received/made since the last
    # analyze
    $dbw->do('ANALYZE');

    return $self->ok('Sync');
}

1;

__END__

=head1 NAME

bif-sync -  exchange updates with hubs

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif sync [OPTIONS...]

=head1 DESCRIPTION

The C<bif sync> command connects to all remote repositories registered
as hubs in the local repository and exchanges updates.

=head1 ARGUMENTS & OPTIONS

=over

=item --hub, -H HUB

Limit the hubs to sync with. This option can be used multiple times.

=item --path, -p PATH

Limit the projects to sync. This option can be used multiple times.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

