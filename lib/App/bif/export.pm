package App::bif::export;
use strict;
use warnings;
use App::bif::Context;
use AnyEvent;
use Bif::Client;
use Coro;

our $VERSION = '0.1.0';

sub run {
    my $ctx = shift;
    $ctx->{no_pager}++;    # causes problems with something in Coro?
    $ctx = App::bif::Context->new($ctx);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Role::Sync?
    my $db = $ctx->dbw;

    my @pinfo;
    foreach my $path ( @{ $ctx->{path} } ) {
        my $pinfo = $db->get_project($path);

        return $ctx->err( 'ProjectNotFound', 'project not found: %s', $path )
          unless $pinfo;

        push( @pinfo, $pinfo );
    }

    my @locations = $db->get_repo_locations( $ctx->{hub} );
    $ctx->err( 'HubNotFound', 'hub not found: %s', $ctx->{hub} )
      unless @locations;

    my $hub = $locations[0];

    foreach my $pinfo (@pinfo) {
        my $exists = $db->get_project( $pinfo->{path} . '@' . $hub->{alias} );

        if ($exists) {
            if ( $exists->{uuid} eq $pinfo->{uuid} ) {
            }
            else {
                return $ctx->err( 'PathExists',
                    'path exists at destination: %s',
                    $pinfo->{path} );
            }
        }
    }

    $|++;    # no buffering
    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db       => $db,
        hub      => $hub->{location},
        on_error => sub {
            $error = shift;
            $cv->send;
        },
    );

    my $stderr = $client->child->stderr;

    my $stderr_watcher;
    $stderr_watcher = AE::io $stderr, 0, sub {
        my $line = $stderr->getline;
        if ( !defined $line ) {
            undef $stderr_watcher;
            return;
        }
        print STDERR "$hub->{alias}: $line";
    };

    my $coro = async {
        eval {
            $db->txn(
                sub {
                    $db->update_repo(
                        {
                            author            => $ctx->{user}->{name},
                            email             => $ctx->{user}->{email},
                            related_update_id => $ctx->{update_id},
                            message =>
                              "export @{$ctx->{path}} $hub->{location}",
                        }
                    );

                    foreach my $pinfo (@pinfo) {
                        $ctx->{update_id} = $db->nextval('updates');
                        my $msg = "[Exported to $hub->{location}]";
                        if ( $ctx->{message} ) {
                            $msg .= "\n\n$ctx->{message}\n";
                        }

                        $db->xdo(
                            insert_into => 'updates',
                            values      => {
                                id        => $ctx->{update_id},
                                parent_id => $pinfo->{first_update_id},
                                author    => $ctx->{user}->{name},
                                email     => $ctx->{user}->{email},
                                message   => $msg,
                            },
                        );

                        $db->xdo(
                            insert_into => 'func_update_project',
                            values      => {
                                id        => $pinfo->{id},
                                update_id => $ctx->{update_id},
                                repo_uuid => $hub->{uuid},
                            },
                        );

                        $db->xdo(
                            insert_into => 'func_merge_updates',
                            values      => { merge => 1 },
                        );

                        my $status = $client->export_project($pinfo);

                        if ( $status eq 'ProjectExported' ) {
                            print "Project exported: $pinfo->{path}\n";
                        }
                        elsif ( $status eq 'ProjectFound' ) {
                            print "Project already exported: $pinfo->{path}\n";
                        }
                        else {
                            $db->rollback;
                            $error = $status;
                            last;
                        }
                    }

                    # Catch up on errors
                    undef $stderr_watcher;
                    $stderr->blocking(0);
                    while ( my $line = $stderr->getline ) {
                        print STDERR "$hub->{alias}: $line";
                    }

                    return;
                }
            );
        };

        $error .= $@ if $@;
        $client->disconnect;
        return $cv->send( !$error );
    };

    return $ctx->ok('Export') if $cv->recv;
    return $ctx->err( 'Unknown', $error );
}

1;
__END__

=head1 NAME

bif-export -  export a project to a remote hub

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif export PATH... HUB [OPTIONS...]

=head1 DESCRIPTION

Export a project to a hub.

=head1 ARGUMENTS & OPTIONS

=over

=item PATH

The path of the local project to export.  An error will be raised if a
project with the same path exists at the remote HUB.

=item HUB

The location of a remote hub or a previously defined hub alias.

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

