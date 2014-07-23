package App::bif::push::project;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0_26';

my $stderr;
my $stderr_watcher;

sub cleanup_errors {
    my $hub = shift;

    undef $stderr_watcher;
    $stderr->blocking(0);

    while ( my $line = $stderr->getline ) {
        print STDERR "$hub: $line";
    }

    return;
}

sub run {
    my $ctx = shift;
    $ctx->{no_pager}++;    # causes problems with something in Coro?
    $ctx = App::bif::Context->new($ctx);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $db = $ctx->dbw;

    my @pinfo;
    foreach my $path ( @{ $ctx->{path} } ) {
        my $pinfo = $ctx->get_project($path);
        push( @pinfo, $pinfo );
    }

    my @locations = $db->get_hub_repos( $ctx->{hub} );
    $ctx->err( 'HubNotFound', 'hub not found: %s', $ctx->{hub} )
      unless @locations;

    my $hub = $locations[0];

    my @new_pinfo;
    foreach my $pinfo (@pinfo) {
        my $exists =
          eval { $ctx->get_project( $pinfo->{path}, $hub->{name} ) };

        if ($exists) {
            if ( $exists->{uuid} eq $pinfo->{uuid} ) {
                print "Already exported to $hub->{name}: $pinfo->{path}\n";
                next;
            }
            else {
                return $ctx->err( 'PathExists',
                    'path exists at destination: %s',
                    $pinfo->{path} );
            }
        }
        push( @new_pinfo, $pinfo );
    }

    return $ctx->ok('PushProject') unless @new_pinfo;
    @pinfo = @new_pinfo;

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db            => $db,
        location      => $hub->{location},
        debug         => $ctx->{debug},
        debug_bifsync => $ctx->{debug_bifsync},
        on_error      => sub {
            $error = shift;
            $cv->send;
        },
    );

    $stderr = $client->child->stderr;

    $stderr_watcher = AE::io $stderr, 0, sub {
        my $line = $stderr->getline;
        if ( !defined $line ) {
            undef $stderr_watcher;
            return;
        }
        print STDERR "$hub->{name}: $line";
    };

    my $coro = async {
        eval {
            $db->txn(
                sub {
                    $ctx->update_localhub(
                        {
                            related_update_id => $ctx->{update_id},
                            message =>
                              "push project @{$ctx->{path}} $hub->{location}",
                        }
                    );

                    foreach my $pinfo (@pinfo) {
                        my $uid = $ctx->new_update(
                            parent_id => $hub->{first_update_id},
                            message   => "Imported $pinfo->{path}",
                        );

                        $db->xdo(
                            insert_into => 'hub_deltas',
                            values      => {
                                update_id  => $uid,
                                hub_id     => $hub->{id},
                                project_id => $pinfo->{id},
                            },
                        );

                        $db->xdo(
                            delete_from => 'hub_related_projects',
                            where       => {
                                hub_id     => $db->get_localhub_id,
                                project_id => $pinfo->{id},
                            },
                        );

                        my $msg = "[ push: $hub->{location} ($hub->{name}) ]";
                        if ( $ctx->{message} ) {
                            $msg .= "\n\n$ctx->{message}\n";
                        }

                        $ctx->{update_id} = $ctx->new_update(
                            parent_id => $pinfo->{first_update_id},
                            message   => $msg,
                        );

                        $db->xdo(
                            insert_into => 'func_update_project',
                            values      => {
                                id        => $pinfo->{id},
                                update_id => $ctx->{update_id},
                                hub_uuid  => $hub->{uuid},
                            },
                        );

                        $db->xdo(
                            insert_into => 'func_merge_updates',
                            values      => { merge => 1 },
                        );
                    }

                    $client->on_update(
                        sub {
                            $ctx->lprint("$hub->{name}: $_[0]");
                        }
                    );

                    my $status = $client->sync_hub( $hub->{id} );

                    if ( $status ne 'RepoSync' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return cleanup_errors( $hub->{name} );
                    }

                    $status = $client->transfer_hub_updates;
                    if ( $status ne 'TransferHubUpdates' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return cleanup_errors( $hub->{name} );
                    }

                    $status = $client->sync_projects;

                    unless ( $status eq 'ProjectSync' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return cleanup_errors( $hub->{name} );
                    }

                    $status = $client->transfer_project_related_updates;

                    if ( $status ne 'TransferProjectRelatedUpdates' ) {
                        $db->rollback;
                        $error = "unexpected status received: $status";
                        return cleanup_errors( $hub->{name} );
                    }
                    print "\n";

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
        print "Project(s) exported: @{ $ctx->{path} }\n";
        return $ctx->ok('PushProject');
    }
    return $ctx->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

bif-push-project -  export a project to a remote hub

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif push project PATH... HUB [OPTIONS...]

=head1 DESCRIPTION

The C<bif push project> command exports a project to a hub.

=head1 ARGUMENTS & OPTIONS

=over

=item PATH

The path of the local project to export.  An error will be raised if a
project with the same path exists at the remote HUB.

=item HUB

The name of a previously registered hub.

=item --message, -m MESSAGE

Add the optional MESSAGE to the update created for this action.

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

