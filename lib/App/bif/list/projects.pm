package App::bif::list::projects;
use strict;
use warnings;
use utf8;
use App::bif::Context;
use DBIx::ThinSQL qw/ qv sq case concat /;
use Term::ANSIColor qw/color/;

our $VERSION = '0.1.0_26';

sub _invalid_status {
    my $self   = shift;
    my $kind   = shift;
    my $ref    = shift // return ();
    my @status = @$ref;
    return () unless @status;

    my %try = map { defined $_ ? ( $_ => 1 ) : () } @status;

    return () unless keys %try;

    map { delete $try{ $_->[0] } } $self->xarrays(
        select_distinct => ['status'],
        from            => $kind . '_status',
        where           => { status => $ref },
    );

    return keys %try;
}

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    my @invalid = _invalid_status( $db, 'project', $ctx->{status} );

    if (@invalid) {
        my ($pcount) = $db->xarray(
            select => 'count(id)',
            from   => 'projects',
        );
        if ($pcount) {
            return $ctx->err( 'InvalidStatus', "invalid status: @invalid" )
              if @invalid;
        }
        else {
            return $ctx->ok('ListProjects');
        }
    }

    my $data;

    if ( $ctx->{hub} ) {
        require Path::Tiny;
        my $dir = Path::Tiny::path( $ctx->{hub} )->absolute if -d $ctx->{hub};
        ( $ctx->{hub_id} ) = $db->xarray(
            select       => 'h.id',
            from         => 'hubs h',
            where        => { 'h.name' => $ctx->{hub} },
            union_select => 'h.id',
            from         => 'hub_repos hr',
            inner_join   => 'hubs h',
            on           => 'h.id = hr.hub_id',
            where        => { 'hr.location' => $ctx->{hub} },
            union_select => 'h.id',
            from         => 'hub_repos hr',
            inner_join   => 'hubs h',
            on           => 'h.id = hr.hub_id',
            where        => { 'hr.location' => $dir },
            limit        => 1,
        );

        return $ctx->err( 'HubNotFound', 'hub not registered: ' . $ctx->{hub} )
          unless $ctx->{hub_id};

        $data = _get_data($ctx);

    }
    else {
        $data = _get_data2($ctx);
    }

    return $ctx->ok('ListProjects') unless $data;

    require Term::ANSIColor;
    my $dark  = Term::ANSIColor::color('dark');
    my $reset = Term::ANSIColor::color('reset');

    # TODO do this as a sub-select?
    foreach my $i ( 0 .. $#$data ) {
        my $row = $data->[$i];
        if ( !$row->[7] ) {
            $row->[1] = $dark . $row->[1];
            $row->[4] = $row->[5] = $row->[6] = '*';
            $row->[6] = '*' . $reset;
        }
        else {
            if ( $row->[6] ) {
                $row->[6] =
                  int( 100 * $row->[6] / ( $row->[6] + $row->[5] + $row->[4] ) )
                  . '%';
            }
            else {
                $row->[6] = '0%';
            }
        }

        $row->[7] = '';
    }

    $ctx->start_pager( scalar @$data );

    print $ctx->render_table(
        ' l l  l  l  r r rl',
        [ 'Type', 'Path', 'Title', 'Phase', 'Open', 'Stalled', 'Progress', '' ],
        $data
    );

    $ctx->end_pager;

    return $ctx->ok('ListProjects');
}

sub _get_data {
    my $ctx = shift;

    return $ctx->db->xarrays(
        select => [
            qv( color('dark') . 'project' . color('reset') )->as('type'),
            case (
                when => 'h.local',
                then => 'p.path',
                else => 'h.name || ":" || p.path',
              )->as('xpath'),
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
            if ( $ctx->{local} ) {
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
            if ( $ctx->{status} ) {
                {
                    'project_status.id'     => \'p.status_id',
                    'project_status.status' => $ctx->{status},
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
                if ( $ctx->{local} ) {
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
                if ( $ctx->{status} ) {
                    inner_join => 'project_status',
                      on       => {
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $ctx->{status},
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
            where            => { 'hrp.hub_id' => $ctx->{hub_id} },
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
                if ( $ctx->{local} ) {
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
                if ( $ctx->{status} ) {
                    inner_join => 'project_status',
                      on       => [
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $ctx->{status},
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
            where      => { 'hrp.hub_id' => $ctx->{hub_id} },
            group_by   => 'p.id',
          )->as('total'),
        on       => 'p.id = total.id',
        where    => { 'hrp.hub_id' => $ctx->{hub_id} },
        group_by => [ 'p.path', 'p.title', 'project_status.status', ],
        order_by => "REPLACE(xpath,':',' ')",
    );
}

sub _get_data2 {
    my $ctx = shift;

    return $ctx->db->xarrays(
        select => [
            qv( color('dark') . 'project' . color('reset') )->as('type'),
            case (
                when => 'h.local',
                then => 'p.path',
                else => 'h.name || ":" || p.path',
              )->as('xpath'),
            'p.title',
            'project_status.status',
            'sum( coalesce( total.open, 0 ) )',
            'sum( coalesce( total.stalled, 0 ) )',
            'sum( coalesce( total.closed, 0 ) )',
            'p.local',
        ],
        from       => 'projects p',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        inner_join => 'project_status',
        on         => do {
            if ( $ctx->{status} ) {
                {
                    'project_status.id'     => \'p.status_id',
                    'project_status.status' => $ctx->{status},
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
            from => 'projects p',
            do {
                if ( $ctx->{status} ) {
                    inner_join => 'project_status',
                      on       => {
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $ctx->{status},
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
                if ( $ctx->{local} ) {
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
                if ( $ctx->{status} ) {
                    inner_join => 'project_status',
                      on       => {
                        'project_status.id'     => \'p.status_id',
                        'project_status.status' => $ctx->{status},
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
                if ( $ctx->{local} ) {
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
            if ( $ctx->{local} ) {
                ( where => 'p.local = 1' );
            }
            else {
                ();
            }
        },
        group_by => [ 'path', 'p.title', 'project_status.status', ],
        order_by => "REPLACE(xpath,':',' ')",
    );
}

1;

__END__

=head1 NAME

bif-list-projects - list projects with task/issue count & progress

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif list projects [STATUS...] [OPTIONS...]

=head1 DESCRIPTION

The C<bif list projects> command lists all projects in the repository,
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

