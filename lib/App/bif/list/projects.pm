package App::bif::list::projects;
use strict;
use warnings;
use utf8;
use Bif::Mo;
use DBIx::ThinSQL qw/ qv sq case coalesce concat /;
use Term::ANSIColor qw/color/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub _invalid_status {
    my $self   = shift;
    my $kind   = shift;
    my $ref    = shift // return ();
    my @status = @$ref;
    return () unless @status;

    my %try = map { defined $_ ? ( $_ => 1 ) : () } @status;

    return () unless keys %try;

    map { delete $try{ $_->[0] } } $self->xarrayrefs(
        select_distinct => ['status'],
        from            => $kind . '_status',
        where           => { status => $ref },
    );

    return keys %try;
}

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    my @invalid = _invalid_status( $db, 'project', $opts->{status} );

    if (@invalid) {
        my $pcount = $db->xval(
            select => 'count(id)',
            from   => 'projects',
        );
        if ($pcount) {
            return $self->err( 'InvalidStatus', "invalid status: @invalid" )
              if @invalid;
        }
        else {
            return $self->ok('ListProjects');
        }
    }

    my $data;

    if ( $opts->{hub} ) {
        require Path::Tiny;
        my $dir = Path::Tiny::path( $opts->{hub} )->absolute if -d $opts->{hub};
        $opts->{hub_id} = $db->xval(
            select       => 'h.id',
            from         => 'hubs h',
            where        => { 'h.name' => $opts->{hub} },
            union_select => 'h.id',
            from         => 'hub_repos hr',
            inner_join   => 'hubs h',
            on           => 'h.id = hr.hub_id',
            where        => { 'hr.location' => $opts->{hub} },
            union_select => 'h.id',
            from         => 'hub_repos hr',
            inner_join   => 'hubs h',
            on           => 'h.id = hr.hub_id',
            where        => { 'hr.location' => $dir },
            limit        => 1,
        );

        return $self->err( 'HubNotFound', 'hub not found: ' . $opts->{hub} )
          unless $opts->{hub_id};

        $data = _get_data($self);

    }
    else {
        $data = _get_data2($self);
    }

    return $self->ok('ListProjects') unless $data;

    require Term::ANSIColor;
    my $dark  = Term::ANSIColor::color('dark');
    my $reset = Term::ANSIColor::color('reset');

    # TODO do this as a sub-select?
    foreach my $i ( 0 .. $#$data ) {
        my $row = $data->[$i];
        if ( !$row->[8] ) {
            $row->[5] = $row->[6] = $row->[7] = '*';
            $row->[4] = $row->[5];
            $row->[7] = '*' . $reset;
        }
        else {
            if ( $row->[7] ) {
                $row->[7] =
                  int( 100 * $row->[7] / ( $row->[7] + $row->[6] + $row->[5] ) )
                  . '%';
            }
            else {
                $row->[7] = '0%';
            }
        }

        $row->[8] = '';
    }

    $self->start_pager( scalar @$data );

    print $self->render_table(
        'll  l  l  l  r r rl',
        [
            ' ',     'TYPE', 'PATH',    'TITLE',
            'PHASE', 'OPEN', 'STALLED', 'PROGRESS',
            ''
        ],
        $data
    );

    return $self->ok('ListProjects');
}

sub _get_data {
    my $self = shift;
    my $opts = $self->opts;

    return $self->db->xarrayrefs(
        select => [
            qv( color('dark') . 'project' . color('reset') )->as('type'),
            'p.fullpath',
            'p.title',
            'project_status.status',
            'sum( coalesce( total.open, 0 ) )',
            'sum( coalesce( total.stalled, 0 ) )',
            'sum( coalesce( total.closed, 0 ) )',
            'p.local',
        ],
        from       => 'hub_related_projects hrp',
        inner_join => 'projects p',
        on         => do {
            if ( $opts->{local} ) {
                {
                    'p.id'    => \'hrp.project_id',
                    'p.local' => 1,
                };
            }
            else {
                'p.id = hrp.project_id';
            }
        },
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        inner_join => 'project_status',
        on         => do {
            if ( $opts->{status} ) {
                {
                    'project_status.id'     => \'p.status_id',
                    'project_status.status' => $opts->{status},
                };
            }
            else {
                'project_status.id = p.status_id';
            }
        },
        left_join => sq(
            select => [
                'p.id',
                "sum(task_status.status = 'open') as open",
                "sum(task_status.status = 'stalled') as stalled",
                "sum(task_status.status = 'closed') as closed",
            ],
            from       => 'hub_related_projects hrp',
            inner_join => 'projects p',
            on         => do {
                if ( $opts->{local} ) {
                    {
                        'p.id'    => \'hrp.project_id',
                        'p.local' => 1,
                    };
                }
                else {
                    'p.id = hrp.project_id';
                }
            },
            do {
                if ( $opts->{status} ) {
                    inner_join => 'project_status',
                      on       => {
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $opts->{status},
                      };
                }
                else {
                    ();
                }
            },
            inner_join       => 'task_status',
            on               => 'task_status.project_id = p.id',
            inner_join       => 'tasks',
            on               => 'tasks.status_id = task_status.id',
            where            => { 'hrp.hub_id' => $opts->{hub_id} },
            group_by         => 'p.id',
            union_all_select => [
                'p.id',
                "sum(issue_status.status = 'open') as open",
                "sum(issue_status.status = 'stalled') as stalled",
                "sum(issue_status.status = 'closed') as closed",
            ],
            from       => 'hub_related_projects hrp',
            inner_join => 'projects p',
            on         => do {
                if ( $opts->{local} ) {
                    {
                        'p.id'    => \'hrp.project_id',
                        'p.local' => 1,
                    };
                }
                else {
                    'p.id = hrp.project_id';
                }
            },
            do {
                if ( $opts->{status} ) {
                    inner_join => 'project_status',
                      on       => [
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $opts->{status},
                      ],
                      ;
                }
                else {
                    ();
                }
            },
            inner_join => 'issue_status',
            on         => 'issue_status.project_id = p.id',
            inner_join => 'project_issues',
            on         => 'project_issues.status_id = issue_status.id',
            where      => { 'hrp.hub_id' => $opts->{hub_id} },
            group_by   => 'p.id',
          )->as('total'),
        on       => 'p.id = total.id',
        where    => { 'hrp.hub_id' => $opts->{hub_id} },
        group_by => [ 'p.path', 'p.title', 'project_status.status', ],
        order_by => [qw/p.path h.name/],
    );
}

sub _get_data2 {
    my $self = shift;
    my $opts = $self->opts;

    my $reset = Term::ANSIColor::color('reset');
    my $bold  = Term::ANSIColor::color('bold');
    return $self->db->xarrayrefs(
        select => [qw/new type path title status open stalled closed local/],
        from   => sq(
            with => 'b',
            as   => sq(
                select => [ 'b.change_id AS start', 'b.change_id2 AS stop' ],
                from   => 'bifkv b',
                where => { 'b.key' => 'last_sync' },
            ),
            select => [
                case (
                    when => 't.first_change_id > b.start',
                    then => qv('+'),
                    when => 'b.start',
                    then => qv('±'),
                    else => qv(' '),
                  )->as('new'),
                qv('project')->as('type'),
                'p.fullpath AS path',
                'p.title AS title',
                'project_status.status',
                'sum( coalesce( total.open, 0 ) ) AS open',
                'sum( coalesce( total.stalled, 0 ) )  AS stalled',
                'sum( coalesce( total.closed, 0 ) ) AS closed',
                'p.local',
                'p.hub_id',
            ],
            from       => 'projects p',
            inner_join => 'topics t',
            on         => 't.id = p.id',
            left_join  => 'b',
            on         => 't.last_change_id BETWEEN b.start AND b.stop',
            left_join  => 'hubs h',
            on         => 'h.id = p.hub_id',
            inner_join => 'project_status',
            on         => do {
                if ( $opts->{status} ) {
                    {
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $opts->{status},
                    };
                }
                else {
                    'project_status.id = p.status_id';
                }
            },
            left_join => sq(
                select => [
                    'p.id',
                    "sum(task_status.status = 'open') as open",
                    "sum(task_status.status = 'stalled') as stalled",
                    "sum(task_status.status = 'done') as closed",
                ],
                from => 'projects p',
                do {
                    if ( $opts->{status} ) {
                        inner_join => 'project_status',
                          on       => {
                            'project_status.id'     => \'p.status_id',
                            'project_status.status' => $opts->{status},
                          };
                    }
                    else {
                        ();
                    }
                },
                inner_join => 'task_status',
                on         => 'task_status.project_id = p.id',
                inner_join => 'tasks',
                on         => 'tasks.status_id = task_status.id',
                do {
                    if ( $opts->{local} ) {
                        ( where => 'p.local = 1' );
                    }
                    else {
                        ();
                    }
                },
                group_by         => 'p.id',
                union_all_select => [
                    'p.id',
                    "sum(issue_status.status = 'open') as open",
                    "sum(issue_status.status = 'stalled') as stalled",
                    "sum(issue_status.status = 'closed') as closed",
                ],
                from => 'projects p',
                do {
                    if ( $opts->{status} ) {
                        inner_join => 'project_status',
                          on       => {
                            'project_status.id'     => \'p.status_id',
                            'project_status.status' => $opts->{status},
                          },
                          ;
                    }
                    else {
                        ();
                    }
                },
                inner_join => 'issue_status',
                on         => 'issue_status.project_id = p.id',
                inner_join => 'project_issues',
                on         => 'project_issues.status_id = issue_status.id',
                do {
                    if ( $opts->{local} ) {
                        ( where => 'p.local = 1' );
                    }
                    else {
                        ();
                    }
                },
                group_by => 'p.id',
              )->as('total'),
            on => 'total.id = p.id',
            do {
                if ( $opts->{local} ) {
                    ( where => 'p.local = 1' );
                }
                else {
                    ();
                }
            },
            group_by => 'p.id',
            order_by => [ 'p.hub_id IS NOT NULL', qw/path/ ],
        ),
    );
}

1;

__END__

=head1 NAME

=for bif-doc #list

bif-list-projects - list projects with task/issue count & progress

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif list projects [STATUS...] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-list-projects> command lists all projects in the repository,
showing counts of the open and stalled topics, and a calculated
progress percentage.

A '*' character in the statistics columns (topic counts, completion %)
is shown for remote-only projects where such information is not known
locally.

=head1 ARGUMENTS & OPTIONS

=over

=item STATUS...

Limit the list by project status type(s).

=item --hub, -H HUB

Limit the list to projects located at HUB.

=item --local, -l

Limit the list to projects that synchronise.

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

