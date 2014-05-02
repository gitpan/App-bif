package App::bif::list::tasks;
use strict;
use warnings;
use utf8;
use App::bif::Context;

our $VERSION = '0.1.0_17';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    DBIx::ThinSQL->import(qw/ qv concat coalesce/);

    my @projects = $db->xarrays(
        select => [ 'projects.id', 'projects.path', 0 ],
        from   => 'projects',

        #        inner_join => 'project_status',
        #        on         => [
        #            'projects.status_id = project_status.id AND ',
        #            'project_status.status = ',
        #            qv('active')
        #        ],
        order_by => 'projects.path',
    );

    require Text::FormatTable;
    my $table = Text::FormatTable->new(' l  l  l ');

    my $i = 0;
    foreach my $project (@projects) {

        my $data = $db->xarrays(
            select => [
                'tasks.id AS id',
                'tasks.title AS title',
                'task_status.status',
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
            order_by => 'id ASC',
        );

        next unless @$data;

        require Term::ANSIColor;
        my $dark  = Term::ANSIColor::color('dark');
        my $bold  = Term::ANSIColor::color('white');
        my $reset = Term::ANSIColor::color('reset');

        $table->rule(' ') if $i;
        $table->head( $bold . 'ID', "Task ($project->[1])", 'Status' . $reset );

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
        }
    }

    if ($i) {
        $ctx->start_pager($i);

        require Term::Size;
        print $table->render( ( Term::Size::chars() )[0] );

        $ctx->end_pager;
    }

    $ctx->ok( 'ListTasks', \@projects );
}

1;
__END__

=head1 NAME

bif-list-tasks - list projects' tasks

=head1 VERSION

0.1.0_17 (2014-05-02)

=head1 SYNOPSIS

    bif list tasks [OPTIONS...]

=head1 DESCRIPTION

Lists the tasks associated with each project.

=head1 OPTIONS

=over

=item --status, -S STATUS

Limit the list to topics with a matching status. Possible values are
"active", "stalled", "resolved", and "ignored". Defaults to "active".

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

