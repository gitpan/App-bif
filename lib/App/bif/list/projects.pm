package App::bif::list::projects;
use strict;
use warnings;
use App::bif::Util;
use Term::ANSIColor;

our $VERSION = '0.1.0';

sub _invalid_status {
    my $self = shift;
    my $kind = shift;
    return () unless @_;

    my %try = map { defined $_ ? ( $_ => 1 ) : () } @_;

    return () unless keys %try;

    map { delete $try{ $_->[0] } } $self->xarrays(
        select_distinct => ['status'],
        from            => $kind . '_status',
        where           => [ 'status IN(', ( map { qv($_) } @_ ), ')' ],
    );

    return keys %try;
}

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_db;

    DBIx::ThinSQL->import(qw/ qv sq /);

    my @invalid = _invalid_status( $db, 'project', $opts->{status} );

    if (@invalid) {
        my ($pcount) = $db->xarray(
            select => 'count(id)',
            from   => 'projects',
        );
        if ($pcount) {
            bif_err( 'InvalidStatus', "invalid status: @invalid" )
              if @invalid;
        }
        else {
            return [];
        }
    }

    do {
        if ( $opts->{all} ) {
        }
        else {
        }
      },

      my $data = $db->xarrays(
        select => [
            'projects.path',         'projects.title',
            'project_status.status', 'sum(total.open)',
            'sum(total.stalled)',    'sum(total.closed)',
        ],
        from       => 'projects',
        inner_join => 'project_status',
        on         => do {
            if ( $opts->{status} ) {
                [
                    'project_status.id = projects.status_id AND ',
                    'project_status.status = ',
                    qv( $opts->{status} )
                ];
            }
            else {
                'project_status.id = projects.status_id';
            }
        },
        left_join => sq(
            select => [
                'projects.id',
                "sum(task_status.status = 'open') as open",
                "sum(task_status.status = 'stalled') as stalled",
                "sum(task_status.status = 'closed') as closed",
            ],
            from => 'projects',
            do {
                if ( $opts->{status} ) {
                    inner_join => 'project_status',
                      on       => [
                        'project_status.id = projects.status_id AND ',
                        'project_status.status = ',
                        qv( $opts->{status} )
                      ];
                }
                else {
                    ();
                }
            },
            inner_join       => 'task_status',
            on               => 'task_status.project_id = projects.id',
            inner_join       => 'tasks',
            on               => 'tasks.status_id = task_status.id',
            group_by         => 'projects.id',
            union_all_select => [
                'projects.id',
                "sum(issue_status.status = 'open') as open",
                "sum(issue_status.status = 'stalled') as stalled",
                "sum(issue_status.status = 'closed') as closed",
            ],
            from => 'projects',
            do {
                if ( $opts->{status} ) {
                    inner_join => 'project_status',
                      on       => [
                        'project_status.id = projects.status_id AND ',
                        'project_status.status = ',
                        qv( $opts->{status} )
                      ],
                      ;
                }
                else {
                    ();
                }
            },
            inner_join => 'issue_status',
            on         => 'issue_status.project_id = projects.id',
            inner_join => 'project_issues',
            on         => 'project_issues.status_id = issue_status.id',
            group_by   => 'projects.id',
          )->as('total'),
        on => 'projects.id = total.id',
        group_by =>
          [ 'projects.path', 'projects.title', 'project_status.status', ],
        order_by => 'projects.path',
      );

    return [] unless @$data;

    my $dark  = Term::ANSIColor::color('dark');
    my $reset = Term::ANSIColor::color('reset');

    # TODO do this as a sub-select?
    foreach my $i ( 0 .. $#$data ) {
        my $row = $data->[$i];
        if ( $row->[5] ) {
            $row->[5] =
              int( 100 * $row->[5] / ( $row->[5] + $row->[3] + $row->[4] ) )
              . '%';
        }
        else {
            $row->[5] = '0%';
        }

        $row->[3] = $dark . '-' . $reset unless $row->[3];
        $row->[4] = $dark . '-' . $reset unless $row->[4];
    }

    start_pager( scalar @$data );

    print render_table( ' l  l  l  r r r ',
        [ 'Project', 'Title', 'Phase', 'Open', 'Stalled', 'Progress' ], $data );

    end_pager;

    return $data;
}

1;

__END__

=head1 NAME

bif-list-projects - list projects with thread counts and progress

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif list projects [OPTIONS...]

=head1 DESCRIPTION

Lists the projects in the repository, showing counts of the open and
stalled topics, and a calculated progress percentage.

=head1 OPTIONS

=over

=item --status, -s STATUS

Limit the list to projects with a matching status.

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

