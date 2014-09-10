package App::bif::drop::project;
use strict;
use warnings;
use parent 'App::bif::Context';
use DBIx::ThinSQL qw/sq/;

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $dbw  = $self->dbw;
    my $info = $self->get_project( $self->{path} );

    if ( !$self->{force} ) {
        print "Nothing dropped (missing --force, -f)\n";
        return $self->ok('DropNoForce');
    }

    my $uuid = substr( $info->{uuid}, 0, 8 );

    $dbw->txn(
        sub {
            my $path =
              $info->{hub_id}
              ? "$info->{path}\@$info->{hub_name}"
              : $info->{path};
            $self->new_update(
                message => '',
                action  => "drop project $path",
            );
            my $res;

            if ( $info->{hub_id} ) {
                $res = $self->drop_shallow($info);
            }
            else {
                $res = $dbw->xdo(
                    delete_from => 'projects',
                    where       => { id => $info->{id} },
                );
            }

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            if ($res) {
                print "Dropped project: $path <$uuid>\n";
                print "(shallow drop - project still exists on hub"
                  . " and shared issues will remain)\n"
                  if $info->{hub_id};
            }
            else {
                $self->err( 'NothingDropped', 'nothing dropped!' );
            }
        }
    );

    return $self->ok('DropProjectShallow') if $info->{hub_id};
    return $self->ok('DropProject');
}

sub drop_shallow {
    my $self = shift;
    my $info = shift;
    my $dbw  = $self->dbw;

    # Drop issues that are not part of any other project
    my $res = $dbw->xdo(
        delete_from => 'issues',
        where       => [
            'id IN ',
            sq(
                select => 'x.issue_id',
                from   => sq(
                    select =>
                      [ 'pi.issue_id', 'COUNT(pi2.project_id) AS total' ],
                    from       => 'project_issues pi',
                    inner_join => 'project_issues pi2',
                    on         => 'pi2.issue_id = pi.issue_id',
                    where      => {
                        'pi.project_id' => $info->{id},
                    },
                    group_by => 'pi.issue_id',
                    having   => 'total = 1',
                )->as('x'),
            ),
        ],
    );

    $res += $dbw->xdo(
        delete_from => 'tasks',
        where       => [
            'status_id IN ',
            sq(
                select => 'ts.id',
                from   => 'task_status ts',
                where  => { 'ts.project_id' => $info->{id} },
            )
        ],
    );

    # Delete project topic entities, except those which are
    # our own identities, project entities, or are also
    # other project topic entities.
    $res += $dbw->xdo(
        delete_from => 'entities',
        where       => [
            'id IN ',
            sq(
                select        => 'pte.entity_id',
                from          => 'project_topic_entities pte',
                where         => { 'pte.project_id' => $info->{id} },
                except_select => 'x.entity_id',
                from          => sq(
                    select           => 'bif.identity_id AS entity_id',
                    from             => 'bifkv bif',
                    where            => { 'bif.key' => 'self' },
                    union_all_select => 'pe.entity_id',
                    from             => 'project_entities pe',
                    where            => { 'pe.project_id' => $info->{id} },
                    union_all_select => 'pte.entity_id',
                    from             => 'project_topic_entities pte',
                    where            => { 'pte.project_id !' => $info->{id} },
                )->as('x'),
            ),
        ],
    );

    $res += $dbw->xdo(
        update => 'projects',
        set    => { local => 0 },
        where  => { id => $info->{id} },
    );
    return $res;
}

1;
__END__

=head1 NAME

bif-drop-project - remove an project from the repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif drop project PATH [OPTIONS...]

=head1 DESCRIPTION

The bif-drop-project command removes a project from the repository.

=head1 ARGUMENTS

=over

=item PATH

A project path or ID.

=back

=head1 OPTIONS

=over

=item --force, -f

Actually do the drop. This option is required as a safety measure to
stop you shooting yourself in the foot.

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

