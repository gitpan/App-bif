package App::bif::push;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_24';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    return $ctx->err( 'NotImplemented', '--copy not implemented yet' )
      if $ctx->{copy};

    my $info = $ctx->get_topic( $ctx->{id} )
      || return $ctx->err( 'TopicNotFound', 'topic not found: ' . $ctx->{id} );

    my $pinfo = $ctx->get_project( $ctx->{path}, $ctx->{hub} );

    if ( $info->{kind} eq 'issue' ) {
        return _push_issue( $ctx, $db, $info, $pinfo );
    }
    elsif ( $info->{kind} eq 'task' ) {
        return $ctx->err( 'NotImplemented',
            'push not implemented: ' . $info->{kind} );
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

    DBIx::ThinSQL->import(qw/concat qv/);

    my @unsatisfied = map { $_->[0] } $db->xarrays(
        select     => concat( 'p.path', qv(' ('), 'h.name', qv(')') ),
        from       => 'project_issues pi',
        inner_join => 'projects p',
        on         => 'p.id = pi.project_id',
        inner_join => 'hubs h',
        on         => 'h.id = p.hub_id',
        where => { 'pi.issue_id' => $info->{id} },
        except_select => concat( 'p2.path', qv(' ('), 'h.name', qv(')') ),
        from          => 'projects p',
        inner_join => 'hub_related_projects hrp',
        on         => 'hrp.hub_id = p.hub_id',
        inner_join => 'projects p2',
        on         => 'p2.id = hrp.project_id',
        inner_join => 'hubs h',
        on         => 'h.id = p2.hub_id',
        where      => { 'p.id' => $pinfo->{id} },
    );

    if (@unsatisfied) {
        my ($name) = $db->xarray(
            select     => [ 'h.name', 'h.local' ],
            from       => 'projects p',
            inner_join => 'hubs h',
            on         => 'h.id = p.hub_id',
            where => { 'p.id' => $pinfo->{id} },
        );

        @unsatisfied = join ', ', @unsatisfied;

        return $ctx->err( 'NoCooperation',
            "$ctx->{path} ($name) has no cooperation with @unsatisfied" );
    }

    $ctx->{message} ||= $ctx->prompt_edit;

    $db->txn(
        sub {
            my $rid = $db->nextval('updates');
            my $uid = $db->nextval('updates');

            my ( $proj, $hub ) = $db->xarray(
                select     => [qw/ p.path h.name /],
                from       => 'projects p',
                inner_join => 'hubs h',
                on         => 'h.id = p.hub_id',
                where      => {
                    'p.id' => $info->{project_id},
                },
            );

            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id        => $uid,
                    parent_id => $info->{first_update_id},
                    email     => $ctx->{user}->{email},
                    author    => $ctx->{user}->{name},
                    message   => "[ Pushed from project "
                      . "$proj\@$hub ]\n\n$ctx->{message}",
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
                    update_id  => $uid,
                    id         => $info->{id},
                    project_id => $pinfo->{id},
                    status_id  => $status_id,
                },
            );

            $ctx->{update_id} = $uid;

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $ctx->update_repo(
                {
                    id      => $rid,
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

bif-push - push a topic to another project

=head1 VERSION

0.1.0_24 (2014-06-13)

=head1 SYNOPSIS

    bif push ID PATH [HUB] [OPTIONS...]

=head1 DESCRIPTION

The C<bif push> command is used to modify the relationship between a
topic and a previously unrelated project. The type of the topic being
pushed determines the type of relationship changes that are possible.

Pushing an issue for example "shares" that topic with another project.
Comments made in any project for that issue will appear everywhere
else, but status changes are project-specific.  In order for that to be
possible however, the destination project must already be cooperating
with all of the projects already associated with the issue.

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

