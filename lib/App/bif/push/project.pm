package App::bif::push::project;
use strict;
use warnings;
use AnyEvent;
use Bif::Sync::Client;
use Bif::Mo;
use Coro;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;

    my @pinfo;
    foreach my $path ( @{ $opts->{path} } ) {
        push( @pinfo, $self->get_project($path) );
    }

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $dbw       = $self->dbw;
    my @locations = $dbw->get_hub_repos( $opts->{hub} );
    $self->err( 'HubNotFound', 'hub not found: %s', $opts->{hub} )
      unless @locations;

    my $hub = $locations[0];

    my @new_pinfo;
    foreach my $pinfo (@pinfo) {
        my $exists = eval { $self->get_project("$hub->{name}/$pinfo->{path}") };

        if ($exists) {
            if ( $exists->{uuid} eq $pinfo->{uuid} ) {
                print "Already exported to $hub->{name}: $pinfo->{path}\n";
                next;
            }
            else {
                return $self->err( 'PathExists',
                    'path exists at destination: %s',
                    $pinfo->{path} );
            }
        }
        push( @new_pinfo, $pinfo );
    }

    return $self->ok('PushProject') unless @new_pinfo;
    @pinfo = @new_pinfo;

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Sync::Client->new(
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
                    foreach my $pinfo (@pinfo) {

                        my $msg = "[ push: $hub->{location} ($hub->{name}) ]";
                        if ( $opts->{message} ) {
                            $msg .= "\n\n$opts->{message}\n";
                        }

                        my $uid = $self->new_change(
                            parent_id => $pinfo->{first_change_id},
                            message   => $msg,
                        );

                        $dbw->xdo(
                            insert_into => 'func_update_project',
                            values      => {
                                id        => $pinfo->{id},
                                change_id => $uid,
                                hub_id    => $hub->{id},
                            },
                        );

                        $dbw->xdo(
                            insert_into => 'change_deltas',
                            values      => {
                                change_id     => $uid,
                                new           => 1,
                                action_format => "push project $pinfo->{path} "
                                  . "(%s) $hub->{name}",
                                action_topic_id_1 => $pinfo->{id},
                            },
                        );

                        $dbw->xdo(
                            insert_into => 'func_merge_changes',
                            values      => { merge => 1 },
                        );
                    }

                    my $status = $client->sync_hub( $hub->{id} );

                    if ( $status ne 'RepoSync' ) {
                        $dbw->rollback;
                        $error = "unexpected status received: $status";
                        return;
                    }

                    $status = $client->transfer_hub_changes;
                    if ( $status ne 'TransferHubChanges' ) {
                        $dbw->rollback;
                        $error = "unexpected status received: $status";
                        return;
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
        print "Project(s) exported: @{ $opts->{path} }\n";
        return $self->ok('PushProject');
    }
    return $self->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

=for bif-doc #sync

bif-push-project -  export a project to a remote hub

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif push project PATH... HUB [OPTIONS...]

=head1 DESCRIPTION

The B<bif-push-project> command exports one or more projects to a hub.

=head1 ARGUMENTS & OPTIONS

=over

=item PATH...

The path(s) of the local project(s) to export.  An error will be raised
if a project with the same path exists at the remote HUB.

=item HUB

The name of a previously registered hub.

=item --message, -m MESSAGE

Add the optional MESSAGE to the change created for this action.

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

