package App::bif::push::project;
use strict;
use warnings;
use parent 'App::bif::Context';
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0_28';

sub run {
    my $self = shift;
    $self->{no_pager}++;    # causes problems with something in Coro?
    $self = __PACKAGE__->new($self);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $db = $self->dbw;

    my @pinfo;
    foreach my $path ( @{ $self->{path} } ) {
        push( @pinfo, $self->get_project($path) );
    }

    my @locations = $db->get_hub_repos( $self->{hub} );
    $self->err( 'HubNotFound', 'hub not found: %s', $self->{hub} )
      unless @locations;

    my $hub = $locations[0];

    my @new_pinfo;
    foreach my $pinfo (@pinfo) {
        my $exists =
          eval { $self->get_project("$pinfo->{path}\@$hub->{name}") };

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
                    foreach my $pinfo (@pinfo) {
                        my $uid = $self->new_change(
                            parent_id => $hub->{first_change_id},
                            message   => "Imported $pinfo->{path}",
                        );

                        $db->xdo(
                            insert_into => 'change_deltas',
                            values      => {
                                change_id     => $uid,
                                new           => 1,
                                action_format => "imported $pinfo->{path} (%s)",
                                action_topic_id_1 => $pinfo->{id},
                            },
                        );

                        # TODO make this a trigger somehow?
                        $db->xdo(
                            insert_into => 'hub_deltas',
                            values      => {
                                change_id  => $uid,
                                hub_id     => $hub->{id},
                                project_id => $pinfo->{id},
                            },
                        );

                        my $msg = "[ push: $hub->{location} ($hub->{name}) ]";
                        if ( $self->{message} ) {
                            $msg .= "\n\n$self->{message}\n";
                        }

                        $self->{change_id} = $self->new_change(
                            parent_id => $pinfo->{first_change_id},
                            message   => $msg,
                        );

                        $db->xdo(
                            insert_into => 'change_deltas',
                            values      => {
                                change_id     => $self->{change_id},
                                new           => 1,
                                action_format => "push project $pinfo->{path} "
                                  . "(%s) $hub->{name}",
                                action_topic_id_1 => $pinfo->{id},
                            },
                        );

                        $db->xdo(
                            insert_into => 'func_change_project',
                            values      => {
                                id        => $pinfo->{id},
                                change_id => $self->{change_id},
                                hub_uuid  => $hub->{uuid},
                            },
                        );

                        $db->xdo(
                            insert_into => 'func_merge_changes',
                            values      => { merge => 1 },
                        );
                    }

                    my $status = $client->sync_hub( $hub->{id} );

                    if ( $status ne 'RepoSync' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return;
                    }

                    $status = $client->transfer_hub_changes;
                    if ( $status ne 'TransferHubChanges' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return;
                    }

                    $status = $client->sync_projects;

                    unless ( $status eq 'ProjectSync' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return;
                    }

                    $status = $client->transfer_project_related_changes;

                    if ( $status ne 'TransferProjectRelatedChanges' ) {
                        $db->rollback;
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
        print "Project(s) exported: @{ $self->{path} }\n";
        return $self->ok('PushProject');
    }
    return $self->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

bif-push-project -  export a project to a remote hub

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif push project PATH... HUB [OPTIONS...]

=head1 DESCRIPTION

The C<bif push project> command exports one or more projects to a hub.

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

