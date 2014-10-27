package App::bif::list::topics;
use strict;
use warnings;
use utf8;
use Bif::Mo;
use DBIx::ThinSQL qw/ qv case concat coalesce sq/;
use Time::Duration qw/concise duration/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    my @projects = $db->xarrayrefs(
        select => [ 'p.id', 'p.fullpath', 'p.hub_id' ],
        from   => 'projects p',
        do {

            if ( $opts->{project_status} ) {
                (
                    inner_join => 'project_status ps',
                    on         => {
                        'p.project_status_id' => \' ps.id',
                        'ps.status'           => $opts->{project_status},
                    }
                );
            }
            else {
                ();
            }
        },
        left_join => 'hubs h',
        on        => 'h.id = p.hub_id',
        order_by  => [ 'p.hub_id IS NOT NULL', 'path' ],
    );

    return $self->ok('ListTopics') unless @projects;

    require Text::FormatTable;

    my $table = Text::FormatTable->new(' l l  l  l  r ');
    my ( $white, $yellow, $reset ) =
      $self->colours( 'yellow', 'yellow', 'reset' );

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
                'tasks.id AS id',
                concat(
                    'tasks.title',
                    case (
                        when => 't.first_change_id > b.start',
                        then => qv( $yellow . ' [+]' . $reset ),
                        when => 'b.start',
                        then => qv( $yellow . ' [±]' . $reset ),
                        else => qv(''),
                    )
                  )->as('title'),
                'task_status.status',
                "strftime('%s','now') - t.ctime",
            ],
            from       => 'task_status',
            inner_join => 'tasks',
            on         => 'tasks.task_status_id = task_status.id',
            inner_join => 'topics t',
            on         => 't.id = tasks.id',
            left_join  => 'b',
            on         => 't.last_change_id BETWEEN b.start AND b.stop',
            where      => {
                'task_status.project_id' => $project->[0],
                do {
                    if ( $opts->{status} ) {
                        ( 'task_status.status' => $opts->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            union_all_select => [
                qv('issue')->as('type'),
                'project_issues.id AS id',
                concat(
                    'issues.title',
                    case (
                        when => 't.first_change_id > b.start',
                        then => qv( $yellow . ' [+]' . $reset ),
                        when => 'b.start',
                        then => qv( $yellow . ' [±]' . $reset ),
                        else => qv(''),
                    )
                  )->as('title'),
                'issue_status.status',
                "strftime('%s','now') - t.ctime AS age",
            ],
            from       => 'issue_status',
            inner_join => 'project_issues',
            on         => 'project_issues.issue_status_id = issue_status.id',
            inner_join => 'issues',
            on         => 'issues.id = project_issues.issue_id',
            inner_join => 'topics t',
            on         => 't.id = issues.id',
            left_join  => 'b',
            on         => 't.last_change_id BETWEEN b.start AND b.stop',
            where      => {
                'issue_status.project_id' => $project->[0],
                do {
                    if ( $opts->{status} ) {
                        ( 'issue_status.status' => $opts->{status} );
                    }
                    else {
                        ();
                    }
                },
            },
            order_by => [ 'age DESC', 'id ASC' ],
        );

        next unless $data;

        if ($i) {
            $i++;
            $table->rule(' ');
        }

        $table->head(
            $white . 'Type',
            'ID', "Topic [$project->[1]]",
            'Status', 'Age' . $reset
        );
        $i++;

        foreach (@$data) {
            $_->[4] = concise( duration( $_->[4], 1 ) ) . $reset;
            $table->row(@$_);
            $project->[2]++;
            $i++;
        }
    }

    $self->start_pager;

    print $table->render( $self->term_width ) . "\n";

    $self->ok( 'ListTopics', \@projects );
}

1;
__END__

=head1 NAME

=for bif-doc #list

bif-list-topics - list projects' tasks and issues

=head1 VERSION

0.1.4 (2014-10-27)

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

