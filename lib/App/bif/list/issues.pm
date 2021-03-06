package App::bif::list::issues;
use strict;
use warnings;
use utf8;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    DBIx::ThinSQL->import(qw/ qv concat coalesce/);

    my @projects = $db->xarrayrefs(
        select => [ 'projects.id', 'projects.path', 0 ],
        from   => 'projects',

        #        inner_join => 'project_status',
        #        on         => [
        #            'projects.project_status_id = project_status.id AND ',
        #            'project_status.status = ',
        #            qv('active')
        #        ],
        order_by => 'projects.path',
    );

    require Text::FormatTable;
    my $table = Text::FormatTable->new(' l  l  l ');

    my $i = 0;
    foreach my $project (@projects) {

        my $data = $db->xarrayrefs(
            select => [
                'project_issues.id AS id',
                'issues.title AS title',
                'issue_status.status',
            ],
            from       => 'issue_status',
            inner_join => 'project_issues',
            on         => 'project_issues.issue_status_id = issue_status.id',
            inner_join => 'issues',
            on         => 'issues.id = project_issues.issue_id',
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
            order_by => 'id ASC',
        );

        next unless $data;

        require Term::ANSIColor;
        my $dark  = Term::ANSIColor::color('yellow');
        my $bold  = Term::ANSIColor::color('white');
        my $reset = Term::ANSIColor::color('reset');

        $table->rule(' ') if $i;
        $table->head( $bold . 'ID', "Issue ($project->[1])",
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
        }
    }

    $self->start_pager;

    print $table->render( $self->term_width );

    $self->ok( 'ListIssues', \@projects );
}

1;
__END__

=head1 NAME

=for bif-doc #list

bif-list-issues - list projects' issues

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif list issues [OPTIONS...]

=head1 DESCRIPTION

Lists the issues associated with each project.

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

