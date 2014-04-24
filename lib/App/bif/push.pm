package App::bif::push;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_14';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    return $ctx->err( 'NotImplemented', '--copy not implemented yet' )
      if $ctx->{copy};

    my $info = $db->get_topic( $ctx->{id} )
      || return $ctx->err( 'TopicNotFound', 'topic not found: ' . $ctx->{id} );

    if ( $ctx->{hub} ) {
    }
    else {
        if ( $info->{kind} eq 'issue' ) {

            my $pinfo = $ctx->get_project( $ctx->{path} )
              || return $ctx->err( 'ProjectNotFound',
                'project not found: ' . $ctx->{path} );

            return _push_issue( $ctx, $db, $info, $pinfo );
        }
        elsif ( $info->{kind} eq 'task' ) {
            return $ctx->err( 'NotImplemented',
                'push not implemented: ' . $info->{kind} );
        }

    }

    return $ctx->err( 'PushInvalid',
        'cannot push thread type: ' . $info->{kind} );
}

sub _push_issue {
    my $ctx   = shift;
    my $db    = shift;
    my $info  = shift;
    my $pinfo = shift;

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

    return $ctx->err( 'AlreadyPushed',
        "$ctx->{id} already has status $ctx->{path}:$existing" )
      if $existing;

    $ctx->{update_id} = $db->nextval('updates');
    $ctx->{message} ||= $ctx->prompt_edit(
        txt => "[pushed from <WHERE> to $ctx->{path}<STATUS>]\n\n" );

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $ctx->{update_id},
                    parent_id => $info->{first_update_id},
                    email     => $ctx->{user}->{email},
                    author    => $ctx->{user}->{name},
                    message   => $ctx->{message},
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
                    update_id  => $ctx->{update_id},
                    status_id  => $status_id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $db->update_repo(
                {
                    author  => $ctx->{user}->{name},
                    email   => $ctx->{user}->{email},
                    message => 'push '
                      . $info->{kind} . ' '
                      . $info->{id} . ' '
                      . $ctx->{path},
                }
            );
        }
    );

    printf( "Issue updated: %d.%d\n", $ctx->{id}, $ctx->{update_id} );
    return $ctx->ok('PushIssue');
}

1;
__END__

=head1 NAME

bif-push - push a thread to another project

=head1 VERSION

0.1.0_14 (2014-04-24)

=head1 SYNOPSIS

    bif push ID PATH [HUB] [OPTIONS...]

=head1 DESCRIPTION

Push a thread to another project.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

A task or issue ID. Required.

=item PATH

The destination project PATH. Required.

=item HUB

The location of the hub where the project is hosted. If not given the
project is assumed to be in the current repository.

=item --copy, -c

[not implemented] Copy the topic instead of its default push behaviour
(link for issues, move for tasks).

=item --message, -m MESSAGE

The push message. An editor will be invoked if this is not given.

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

