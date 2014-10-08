package App::bif::sync;
use strict;
use warnings;
use AnyEvent;
use Bif::Client;
use Bif::Mo;
use Coro;
use DBIx::ThinSQL qw/qv/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
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

        my $client = Bif::Client->new(
            name          => $hub->{name},
            db            => $dbw,
            location      => $hub->{location},
            debug         => $opts->{debug},
            debug_bifsync => $opts->{debug_bifsync},
            on_update     => sub {
                $self->lprint("$hub->{name}: $_[0]");
            },
            on_error => sub {
                $error = shift;
                $cv->send;
            },
        );

        my $coro = async {
            select $App::bif::pager->fh if $opts->{debug};

            eval {
                $dbw->txn(
                    sub {
                        my $uid = $dbw->nextval('changes');

                        my $status = $client->sync_hub( $hub->{id} );

                        unless ( $status eq 'RepoMatch'
                            or $status eq 'RepoSync' )
                        {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return;

                        }

                        if ( $status eq 'RepoSync' ) {
                            $status = $client->transfer_hub_changes;
                            if ( $status ne 'TransferHubChanges' ) {
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

                        $status = $client->transfer_project_related_changes;

                        if ( $status ne 'TransferProjectRelatedChanges' ) {
                            $dbw->rollback;
                            $error = "unexpected status received: $status";
                            return;
                        }
                        print "\n";

                        $self->new_change(
                            id => $uid,
                            message =>
                              "sync hub $hub->{name} via $hub->{location}"
                              . $opts->{message},
                        );

                        $dbw->xdo(
                            insert_into => 'change_deltas',
                            values      => {
                                new           => 1,
                                change_id     => $uid,
                                action_format => "sync hub $hub->{name} (%s)",
                                action_topic_id_1 => $hub->{id},
                            },
                        );

                        $dbw->xdo(
                            insert_into => 'func_merge_changes',
                            values      => { merge => 1 },
                        );

                        $dbw->xdo(
                            insert_or_replace_into =>
                              [ 'bifkv', qw/key change_id change_id2/ ],
                            select => [ qv('last_sync'), $uid, 'MAX(c.id)', ],
                            from   => 'changes c',
                        );

                        return;
                    }
                );
            };

            if ($@) {
                $error = $@;
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

    # TODO make this dependent on how many changes received/made since the last
    # analyze
    $dbw->do('ANALYZE');

    return $self->ok('Sync');
}

1;

__END__

=head1 NAME

=for bif-doc #sync

bif-sync -  exchange changes with hubs

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif sync [OPTIONS...]

=head1 DESCRIPTION

The C<bif sync> command connects to all remote repositories registered
as hubs in the local repository and exchanges changes.

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

