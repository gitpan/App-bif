package App::bif::list::issue_status;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_25';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    my $pinfo = $ctx->get_project( $ctx->{path} );

    DBIx::ThinSQL->import(qw/ qv case /);

    my $data = $db->xarrays(
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

    $ctx->start_pager( scalar @$data );

    print $ctx->render_table( ' l  l  l  r  l ',
        [ 'ID', 'State', 'Status', 'Rank', 'Default' ], $data );

    $ctx->end_pager;

    return $data;
}

1;
__END__

=head1 NAME

bif-list-issue-status - list valid issue status/status values

=head1 VERSION

0.1.0_25 (2014-06-14)

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

