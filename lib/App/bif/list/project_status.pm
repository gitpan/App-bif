package App::bif::list::project_status;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_db;

    my $id = $db->path2project_id( $opts->{path} )
      || bif_err( 'PathNotFound', 'project not found: ' . $opts->{path} );

    DBIx::ThinSQL->import(qw/ qv case /);

    my $data = $db->xarrays(
        select => [ 'id', 'status', 'status', 'rank', ],
        from   => 'project_status',
        where    => { project_id => $id },
        order_by => 'rank',

    );

    start_pager( scalar @$data );

    print render_table( ' l  l  l  r ',
        [ 'ID', 'State', 'Status', 'Rank' ], $data );

    end_pager;

    return $data;
}

1;
__END__

=head1 NAME

bif-list-project-status - list valid project status/status values

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif list project-status PATH [OPTIONS...]

=head1 DESCRIPTION

Lists all the status and status combinations that a project can have.

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

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

