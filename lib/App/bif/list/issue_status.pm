package App::bif::list::issue_status;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    my $pinfo = $self->get_project( $opts->{path} );

    DBIx::ThinSQL->import(qw/ qv case /);

    my $data = $db->xarrayrefs(
        select => [
            'id', 'status', 'status', 'rank',
            case (
                when => 'def IS NOT NULL',
                then => qv('*'),
                else => qv(''),
            )->as('Default'),
        ],
        from     => 'issue_status',
        where    => { project_id => $pinfo->{id} },
        order_by => 'rank',

    );

    $self->start_pager( scalar @$data );

    print $self->render_table( ' l  l  l  r  l ',
        [ 'ID', 'State', 'Status', 'Rank', 'Default' ], $data );

    return $data;
}

1;
__END__

=head1 NAME

=for bif-doc #list

bif-list-issue-status - list valid issue status/status values

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif list issue-status PATH [OPTIONS...]

=head1 DESCRIPTION

Lists all the status and status combinations that a issue can have in a
particular project.

=head1 ARGUMENTS

=over

=item PATH

The project path. Required.

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

