package App::bif::pull::project;
use strict;
use warnings;
use parent 'App::bif::Context';
use AnyEvent;
use Bif::Client;
use Coro;
use DBIx::ThinSQL qw/qv/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = shift;
    $self->{no_pager}++;    # causes problems with something in Coro?
    $self = __PACKAGE__->new($self);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $db = $self->dbw;

    my @pinfo;
    foreach my $path ( @{ $self->{path} } ) {
        my $pinfo = $self->get_project($path);

        if ( $pinfo->{local} ) {
            print "Already imported: $pinfo->{path}\n";
            next;
        }

        push( @pinfo, $pinfo );
    }

    return $self->ok('PullProject')
      unless @pinfo;

    my %hubs = map { $_->{hub_id} => 1 } @pinfo;
    return $self->err( 'TooManyHubs', 'can only pull from a single hub' )
      unless 1 == scalar keys %hubs;

    my @repos = $db->get_hub_repos( keys %hubs );
    my $hub   = $repos[0];

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        name          => $hub->{name},
        db            => $db,
        location      => $hub->{location},
        debug         => $self->{debug},
        debug_bifsync => $self->{debug_bifsync},
        on_update     => sub {
            $self->lprint("$hub->{name}: $_[0]");
        },
        on_error => sub {
            $error = shift;
            $cv->send;
        },
    );

    my $coro = async {
        eval {
            $db->txn(
                sub {
                    my $uid = $db->get_max_change_id + 1;

                    foreach my $pinfo (@pinfo) {
                        my $tmp =
                          $self->new_change( message =>
                                "pull project $pinfo->{path}\@$hub->{name}"
                              . " from $hub->{location}" );

                        $db->xdo(
                            insert_into => 'change_deltas',
                            values      => {
                                new           => 1,
                                change_id     => $tmp,
                                action_format => "pull project (%s) "
                                  . "$pinfo->{path}\@$hub->{name}",
                                action_topic_id_1 => $pinfo->{id},
                            },
                        );

                        $db->xdo(
                            update => 'projects',
                            set    => 'local = 1',
                            where  => { id => $pinfo->{id} },
                        );

                    }

                    my $status = $client->sync_hub( $hub->{id} );

                    unless ( $status eq 'RepoMatch'
                        or $status eq 'RepoSync' )
                    {
                        $db->rollback;
                        $error = " unexpected status received : $status ";
                        return;

                    }

                    if ( $status eq 'RepoSync' ) {
                        $status = $client->transfer_hub_changes;

                        if ( $status ne 'TransferHubChanges' ) {
                            $db->rollback;
                            $error = " unexpected status received : $status ";
                            return;
                        }
                    }

                    $status = $client->sync_projects;

                    unless ( $status eq 'ProjectSync' ) {
                        $db->rollback;
                        $error = " unexpected status received : $status ";
                        return;
                    }

                    $status = $client->transfer_project_related_changes;

                    if ( $status ne 'TransferProjectRelatedChanges' ) {
                        $db->rollback;
                        $error = " unexpected status received : $status ";
                        return;
                    }

                    $db->xdo(
                        insert_into => 'func_merge_changes',
                        values      => { merge => 1 },
                    );

                    $db->xdo(
                        insert_or_replace_into =>
                          [ 'bifkv', qw/key change_id change_id2/ ],
                        select => [ qv('last_sync'), $uid, 'MAX(c.id)', ],
                        from   => 'changes c',
                    );

                    print " \n ";
                    return;
                }
            );
        };

        if ($@) {
            $error = $@;
            print " \n ";
        }

        $client->disconnect;
        return $cv->send( !$error );
    };

    if ( $cv->recv ) {
        $db->do('ANALYZE');
        return $self->ok('PullProject');
    }

    return $self->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

bif-pull-project -  import projects from a remote hub

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif pull project PATH...

=head1 DESCRIPTION

The L<bif-pull-project> command imports remote projects from a hub. If
a project has been imported, then it is considered "local". If it has
not been imported then we call it "remote".

For example:

=begin bif

    bif init
    bif pull hub org@provider

=end bif

    bif pull todo@hub

=head1 ARGUMENTS

=over

=item PATH...

The full path(s) (in the form PATH@HUB) of the remote project(s) to
import.

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

