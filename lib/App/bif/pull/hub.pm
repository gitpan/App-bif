package App::bif::pull::hub;
use strict;
use warnings;
use AnyEvent;
use Bif::Client;
use Bif::Mo;
use Coro;
use DBIx::ThinSQL qw/qv/;
use Log::Any '$log';
use Path::Tiny;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;

    # Do this early so that we complain about missing repo before we
    # complain about a missing hub
    my $dbw = $self->dbw;    # Consider upping PRAGMA cache_size?
                             #Or handle that in Bif::Role::Sync?

    if ( $opts->{location} =~ m!^ssh://(.+)! ) {
    }
    elsif ( -d $opts->{location} ) {
        $opts->{location} = path( $opts->{location} )->realpath;
    }
    else {
        return $self->err( 'HubNotFound', 'hub not found: %s',
            $opts->{location} );
    }

    $log->debug("pull hub: $opts->{location}");

    my @locations = $dbw->get_hub_repos( $opts->{location} );

    return $self->err(
        'RepoExists', 'hub already pulled: %s (%s)',
        $locations[0]->{location}, ( $locations[0]->{name} || '' )
    ) if (@locations);

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        name          => $opts->{location},
        db            => $dbw,
        location      => $opts->{location},
        debug         => $opts->{debug},
        debug_bifsync => $opts->{debug_bifsync},
        on_update     => sub {
            $self->lprint("$opts->{location}: $_[0]");
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

                    my ( $status, $ref ) = $client->pull_hub;

                    print "\n";

                    $client->disconnect;

                    if ( $status ne 'RepoImported' ) {
                        $error = $status;
                        $dbw->rollback;
                        return $status;
                    }

                    my @repos = $dbw->xhashrefs(
                        select    => [ 'h.name', 'hr.id', 'hr.location' ],
                        from      => 'hubs h',
                        left_join => 'hub_repos hr',
                        on    => 'hr.hub_id = h.id',
                        where => { 'h.id' => $ref->[0] },
                        limit => 1,
                    );

                    my $repo;
                    foreach my $try (@repos) {
                        $repo = $try if $try->{location} eq $opts->{location};
                    }

                    unless ($repo) {
                        $repo = $repos[0];
                        warn "no match for default repo";
                    }

                    $dbw->xdo(
                        update => 'hubs',
                        set    => { default_repo_id => $repo->{id} },
                        where  => { id => $ref->[0] },
                    );

                    $self->new_change(
                        id => $uid,
                        message =>
                          "Registered hub $repo->{name} at $opts->{location}",
                    );

                    $dbw->xdo(
                        insert_into => 'change_deltas',
                        values      => {
                            new               => 1,
                            change_id         => $uid,
                            action_format     => "pull hub (%s) $repo->{name}",
                            action_topic_id_1 => $ref->[0],
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

                    print "Hub pulled: $repo->{name}\n";
                    return $status;
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

    return $self->ok('PullHub') if $cv->recv;
    return $self->err( 'Unknown', $error );

}

1;
__END__

=head1 NAME

=for bif-doc #sync

bif-pull-hub -  import project lists from a remote repository

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif pull hub LOCATION [OPTIONS...]

=head1 DESCRIPTION

The B<bif-pull-hub> command connects to a hub repository to obtain the
list of projects hosted there.  A hub has a name (use the
L<bif-list-hubs> command to display it) which is useable afterwards
with all other hub-aware commands to save typing the full address.

The retrieved project list is stored locally and is used by the
L<bif-pull-project> and L<bif-push-issue> commands, and changed by the
L<bif-sync> command.

=head1 ARGUMENTS & OPTIONS

=over

=item LOCATION

The location of a remote repository.

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

