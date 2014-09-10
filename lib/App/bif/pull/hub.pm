package App::bif::pull::hub;
use strict;
use warnings;
use parent 'App::bif::Context';
use AnyEvent;
use Bif::Client;
use Coro;
use Log::Any '$log';
use Path::Tiny;

our $VERSION = '0.1.0_27';

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?
    my $self = __PACKAGE__->new($opts);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw = $self->dbw;

    if ( $self->{location} =~ m!^ssh://(.+)! ) {
    }
    elsif ( -d $self->{location} ) {
        $self->{location} = path( $self->{location} )->realpath;
    }
    else {
        return $self->err( 'HubNotFound', 'hub not found: %s',
            $self->{location} );
    }

    $log->debug("pull hub: $self->{location}");

    my @locations = $dbw->get_hub_repos( $self->{location} );

    return $self->err(
        'RepoExists', 'hub already pulled: %s (%s)',
        $locations[0]->{location}, ( $locations[0]->{name} || '' )
    ) if (@locations);

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        name          => $self->{location},
        db            => $dbw,
        location      => $self->{location},
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
                    my $uid = $dbw->nextval('updates');

                    $client->on_update(
                        sub {
                            $self->lprint("$self->{location}: $_[0]");
                        }
                    );

                    my $previous = $dbw->get_max_update_id;
                    my $status   = $client->pull_hub;

                    print "\n";

                    $client->disconnect;

                    if ( $status ne 'RepoImported' ) {
                        $error = $status;
                        $dbw->rollback;
                        return $status;
                    }

                    my $current = $dbw->get_max_update_id;
                    my $delta   = $current - $previous;

                    my ( $hid, $rid, $name ) = $dbw->xlist(
                        select     => [ 'h.id', 'hr.id', 'h.name' ],
                        from       => 'hub_repos hr',
                        inner_join => 'hubs h',
                        on         => 'h.id = hr.hub_id',
                        where => { 'hr.location' => $self->{location} },
                    );

                    $dbw->xdo(
                        update => 'hubs',
                        set    => { default_repo_id => $rid },
                        where  => { id => $hid },
                    );

                    $self->new_update(
                        id      => $uid,
                        action  => "pull hub $name",
                        message => "Registered hub $name via $self->{location}",
                    );

                    $dbw->xdo(
                        insert_or_replace_into => 'bifkv',
                        values                 => {
                            key       => 'last_sync',
                            update_id => $uid,
                        },
                    );

                    print "Hub pulled: $name\n";
                    return $status;
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

    return $self->ok('PullHub') if $cv->recv;
    return $self->err( 'Unknown', $error );

}

1;
__END__

=head1 NAME

bif-pull-hub -  import project lists from a remote repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif pull hub LOCATION [OPTIONS...]

=head1 DESCRIPTION

The B<bif-pull-hub> command connects to a hub repository to obtain the
list of projects hosted there.  A hub has a name (use the
L<bif-list-hubs> command to display it) which is useable afterwards
with all other hub-aware commands to save typing the full address.

The retrieved project list is stored locally and is used by the
L<bif-pull-project> and L<bif-push-issue> commands, and updated by the
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

