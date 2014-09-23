package App::bif::list::topics;
use strict;
use warnings;
use utf8;
use parent 'App::bif::Context';
use Time::Duration qw/concise duration/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;

    require Term::ANSIColor;
    my $dark  = Term::ANSIColor::color('dark');
    my $bold  = Term::ANSIColor::color('bold');
    my $white = Term::ANSIColor::color('dark white');
    my $reset = Term::ANSIColor::color('reset');

    DBIx::ThinSQL->import(qw/ qv case concat coalesce sq/);

    my @projects = $db->xarrayrefs(
        select =>
          [ 'p.id', "p.path || COALESCE('\@' || h.name, '') AS path", 0 ],
        from => 'projects p',
        do {

            if ( $self->{project_status} ) {
                (
                    inner_join => 'project_status ps',
                    on         => {
                        'p.status_id' => \' ps.id',
                        'ps.status'   => $self->{project_status},
                    }
                );
            }
            else {
                ();
            }
        },
        left_join => 'hubs h',
        on        => 'h.id = p.hub_id',
        order_by  => [ 'p.path', 'h.name' ],
    );

    return $self->ok('ListTopics') unless @projects;

    require Text::FormatTable;
    my $table = Text::FormatTable->new(' l r  l  l  r ');

    my $i = 0;
    foreach my $project (@projects) {

        my $data = $db->xarrayrefs(
            with => 'b',
            as   => sq(
                select => [ 'b.change_id AS start', 'b.change_id2 AS stop' ],
                from   => 'bifkv b',
                where => { 'b.key' => 'last_sync' },
            ),
            select => [
                qv('task')->as('type'),
                concat(
                    case (
                        when => 'b.start',
                        then => qv($bold),
                        else => qv(''),
                    ),
                    'tasks.id',
                  )->as('id'),
                'tasks.title AS title',
                'task_status.status',
                "strftime('%s','now') - t.ctime",
            ],
            from       => 'task_status',
            inner_join => 'tasks',
            on         => 'tasks.status_id = task_status.id',
            inner_join => 'topics t',
            on         => 't.id = tasks.id',
            left_join  => 'b',
            on         => 't.last_change_id BETWEEN b.start AND b.stop',
            where      => {
                'task_status.project_id' => $project->[0],
                do {
                    if ( $self->{status} ) {
                        ( 'task_status.status' => $self->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            union_all_select => [
                qv('issue')->as('type'),
                concat(
                    case (
                        when => 'b.start',
                        then => qv($bold),
                        else => qv(''),
                    ),
                    'project_issues.id',
                  )->as('id'),
                'issues.title AS title',
                'issue_status.status',
                "strftime('%s','now') - t.ctime AS age",
            ],
            from       => 'issue_status',
            inner_join => 'project_issues',
            on         => 'project_issues.status_id = issue_status.id',
            inner_join => 'issues',
            on         => 'issues.id = project_issues.issue_id',
            inner_join => 'topics t',
            on         => 't.id = issues.id',
            left_join  => 'b',
            on         => 't.last_change_id BETWEEN b.start AND b.stop',
            where      => {
                'issue_status.project_id' => $project->[0],
                do {
                    if ( $self->{status} ) {
                        ( 'issue_status.status' => $self->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            order_by => [ 'age ASC', 'id ASC' ],
        );

        next unless $data;

        if ($i) {
            $i++;
            $table->rule(' ');
        }

        $table->head(
            $white . 'TYPE',
            'ID', uc( $project->[1] ),
            'STATUS', 'AGE' . $reset
        );
        $i++;

        foreach (@$data) {
            $_->[4] = concise( duration( $_->[4], 1 ) ) . $reset;
            $table->row(@$_);
            $project->[2]++;
            $i++;
        }
    }

    $self->start_pager($i);

    print $table->render($App::bif::Context::term_width);

    $self->end_pager;

    $self->ok( 'ListTopics', \@projects );
}

1;
__END__

=head1 NAME

bif-list-topics - list projects' tasks and issues

=head1 VERSION

0.1.0_28 (2014-09-23)

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

