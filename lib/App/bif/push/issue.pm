package App::bif::push::issue;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::Context';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $info = $self->get_topic( $self->{id} );

    return $self->err( 'NotAnIssue', 'not an issue topic: ' . $info->{id} )
      unless $info->{kind} eq 'issue';

    state $thinsql = DBIx::ThinSQL->import(qw/concat qv/);
    my $db = $self->dbw;

    $db->txn(
        sub {

            foreach my $path ( @{ $self->{path} } ) {

                my $pinfo = $self->get_project( $path, $self->{hub} );

                my $existing = $db->xval(
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
                        'project_issues.id' => $info->{project_issue_id},
                    },
                );

                if ($existing) {
                    if ( $self->{err_on_exists} ) {
                        return $self->err( 'DestinationExists',
                            "$self->{id} already has status $path:$existing\n"
                        );
                    }
                    else {
                        print
                          "$self->{id} already has status $path:$existing\n";
                        next;
                    }
                }

                my @unsatisfied = map { $_->[0] } $db->xarrayrefs(
                    select     => concat( 'p.path', qv('@'), 'h.name' ),
                    from       => 'project_issues pi',
                    inner_join => 'projects p',
                    on         => 'p.id = pi.project_id',
                    inner_join => 'hubs h',
                    on         => 'h.id = p.hub_id',
                    where => { 'pi.issue_id' => $info->{id} },
                    except_select => concat( 'p2.path', qv('@'), 'h.name' ),
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
                    my $name = $db->xval(
                        select     => [ 'h.name', 'h.local' ],
                        from       => 'projects p',
                        inner_join => 'hubs h',
                        on         => 'h.id = p.hub_id',
                        where => { 'p.id' => $pinfo->{id} },
                    );

                    @unsatisfied = join ', ', @unsatisfied;

                    return $self->err( 'NoCooperation',
                        "$path\@$name has no cooperation with @unsatisfied" );
                }

                $self->{message} ||= $self->prompt_edit;

                my $rid = $db->nextval('changes');

                my $src = $db->xval(
                    select => "p.path || COALESCE('\@' || h.name, '') AS path",
                    from   => 'projects p',
                    left_join => 'hubs h',
                    on        => 'h.id = p.hub_id',
                    where     => { 'p.id' => $info->{project_id}, },
                );

                my $dest = $db->xval(
                    select => "p.path || COALESCE('\@' || h.name, '') AS path",
                    from   => 'projects p',
                    left_join => 'hubs h',
                    on        => 'h.id = p.hub_id',
                    where     => { 'p.id' => $pinfo->{id}, },
                );

                my $uid = $self->new_change(
                    parent_id => $info->{first_change_id},
                    message   => "[ forked: $src -> $dest ]\n\n"
                      . $self->{message},
                    action => 'push issue',
                );

                my $status_id = $db->xval(
                    select => 'id',
                    from   => 'issue_status',
                    where  => {
                        project_id => $pinfo->{id},
                        def        => 1,
                    },
                );

                $db->xdo(
                    insert_into => 'func_change_issue',
                    values      => {
                        change_id  => $uid,
                        id         => $info->{id},
                        project_id => $pinfo->{id},
                        status_id  => $status_id,
                    },
                );

                $self->{change_id} = $uid;

                $db->xdo(
                    insert_into => 'func_merge_changes',
                    values      => { merge => 1 },
                );

                printf( "Issue pushed: %d.%d\n",
                    $self->{id}, $self->{change_id} );
            }
        }
    );

    return $self->ok('PushIssue');
}

1;
__END__

=head1 NAME

bif-push-issue - push an issue to another project

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif push issue ID PATH [OPTIONS...]

=head1 DESCRIPTION

The C<bif push issue> command is used to modify the relationship
between a topic and a previously unrelated project. The type of the
topic being pushed determines the type of relationship changes that are
possible.

Pushing an issue for example "shares" that topic with another project.
Comments made in any project for that issue will appear everywhere
else, but status changes are project-specific.  In order for that to be
possible however, the destination project must already be cooperating
with all of the projects already associated with the issue.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An issue ID. Required.

=item PATH

The destination project PATH. Required.

=item --error-on-exists

Raise an error in the event the issue already exists at the destination
project.

=item --message, -m MESSAGE

The push message if desired.

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

