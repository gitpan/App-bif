package App::bif::list::topics;
use strict;
use warnings;
use utf8;
use App::bif::Context;

our $VERSION = '0.1.0_23';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    require Term::ANSIColor;
    my $dark  = Term::ANSIColor::color('dark');
    my $bold  = Term::ANSIColor::color('white');
    my $reset = Term::ANSIColor::color('reset');

    DBIx::ThinSQL->import(qw/ qv concat coalesce/);

    my @projects = $db->xarrays(
        select => [ 'p.id', 'p.path', 0 ],
        from   => 'projects p',
        do {
            if ( $ctx->{project_status} ) {
                (
                    inner_join => 'project_status ps',
                    on         => {
                        'p.status_id' => \' ps.id',
                        'ps.status'   => $ctx->{project_status},
                    }
                );
            }
            else {
                ();
            }
        },
        where    => 'p.local = 1',
        order_by => 'p.path',
    );

    return $ctx->ok('ListTopics') unless @projects;

    require Text::FormatTable;
    my $table = Text::FormatTable->new(' l  l  l ');

    my $i = 0;
    foreach my $project (@projects) {

        my $data = $db->xarrays(
            select => [
                'tasks.id AS id',
                'tasks.title AS title',
                concat( 'task_status.status',
                    qv( ' ' . $dark . '(task)' . $reset ) )->as('status'),
            ],
            from       => 'task_status',
            inner_join => 'tasks',
            on         => 'tasks.status_id = task_status.id',
            where      => {
                'task_status.project_id' => $project->[0],
                do {
                    if ( $ctx->{status} ) {
                        ( 'task_status.status' => $ctx->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            union_all_select => [
                'project_issues.id',
                'issues.title AS title',
                concat( 'issue_status.status',
                    qv( ' ' . $dark . '(issue)' . $reset ) )->as('status'),
            ],
            from       => 'issue_status',
            inner_join => 'project_issues',
            on         => 'project_issues.status_id = issue_status.id',
            inner_join => 'issues',
            on         => 'issues.id = project_issues.issue_id',
            where      => {
                'issue_status.project_id' => $project->[0],
                do {
                    if ( $ctx->{status} ) {
                        ( 'issue_status.status' => $ctx->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            order_by => 'id ASC',
        );

        next unless @$data;

        $table->rule(' ') if $i;
        $table->head( $bold . 'ID', "[$project->[1]] Topic",
            'Status' . $reset );

        if ($dark) {
            $table->rule( $dark . '–' . $reset );
        }
        else {
            $table->rule('-');
        }

        $i++;

        foreach (@$data) {
            $table->row(@$_);
            $project->[2]++;
            $i++;
        }
    }

    $ctx->start_pager($i);

    print $table->render($App::bif::Context::term_width);

    $ctx->end_pager;

    $ctx->ok( 'ListTopics', \@projects );
}

1;
__END__

=head1 NAME

bif-list-topics - list projects' tasks and issues

=head1 VERSION

0.1.0_23 (2014-06-04)

=head1 SYNOPSIS

    bif list topics [OPTIONS...]

=head1 DESCRIPTION

Lists the task and issues associated with each project.

=head1 OPTIONS

=over

=item --status, -S STATUS

Limit the list to topics with a matching status. Possible values are
"active", "stalled", "resolved", and "ignored". Defaults to "active".

=item --all, -a

List all topics for the projects, ignoring whatever the --status option
is set to.

=item --project-status, -P STATUS

Limit the list to projects with a matching status. Possible values are
"active", "stalled", "resolved", and "ignored". Defaults to "active".

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

