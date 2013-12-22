package App::bif::push;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_dbw;

    bif_err( 'NotImplemented', '--copy not implemented yet' )
      if $opts->{copy};

    my $info = $db->get_topic( $opts->{id} )
      || bif_err( 'TopicNotFound', 'topic not found: ' . $opts->{id} );

    if ( $opts->{hub} ) {
    }
    else {
        if ( $info->{kind} eq 'issue' ) {

            my $pinfo = $db->get_project( $opts->{path} )
              || bif_err( 'ProjectNotFound',
                'project not found: ' . $opts->{path} );

            return _push_issue( $opts, $db, $info, $pinfo );
        }
        elsif ( $info->{kind} eq 'task' ) {
            bif_err( 'NotImplemented',
                'push not implemented: ' . $info->{kind} );
        }

    }

    bif_err( 'PushInvalid', 'cannot push thread type: ' . $info->{kind} );
}

sub _push_issue {
    my $opts   = shift;
    my $db     = shift;
    my $info   = shift;
    my $pinfo  = shift;
    my $config = bif_conf;

    my ($existing) = $db->xarray(
        select     => 'issue_status.status',
        from       => 'project_issues',
        inner_join => 'project_issues AS pi2',
        on         => {
            'pi2.issue_id'   => \'project_issues.issue_id',
            'pi2.project_id' => $pinfo->{id},
        },
        inner_join => 'issue_status',
        on         => 'issue_status.id = pi2.status_id',
        where      => {
            'project_issues.id' => $info->{id},
        },
    );

    bif_err( 'AlreadyPushed',
        "$opts->{id} already has status $opts->{path}:$existing" )
      if $existing;

    $opts->{update_id} = $db->nextval('updates');
    $opts->{email}   ||= $config->{user}->{email};
    $opts->{author}  ||= $config->{user}->{name};
    $opts->{message} ||= prompt_edit(
        txt => "[pushed from <WHERE> to $opts->{path}<STATUS>]\n\n" );

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $opts->{update_id},
                    parent_id => $info->{first_update_id},
                    email     => $opts->{email},
                    author    => $opts->{author},
                    message   => $opts->{message},
                },
            );

            my ($status_id) = $db->xarray(
                select => 'id',
                from   => 'issue_status',
                where  => {
                    project_id => $pinfo->{id},
                    def        => 1,
                },
            );

            $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id         => $info->{id},
                    project_id => $pinfo->{id},
                    update_id  => $opts->{update_id},
                    status_id  => $status_id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    printf( "Issue updated: %d.%d\n", $opts->{id}, $opts->{update_id} );
    return $opts;
}

1;
__END__

=head1 NAME

bif-push - push a thread to another project

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif push ID PATH [HUB] [OPTIONS...]

=head1 DESCRIPTION

Push a thread to another project.

=head1 ARGUMENTS

=over

=item ID

A task or issue ID. Required.

=item PATH

The destination project PATH. Required.

=item HUB

The location of the hub where the project is hosted. If not given the
project is assumed to be in the current repository.

=head1 OPTIONS

=item --alias, -a NAME

The alias to refer to the hub in future calls.

=item --copy, -c

Copy the topic instead of its default push behaviour (link for issues,
move for tasks).

=item --message, -m MESSAGE

The push message. An editor will be invoked if this is not given.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

