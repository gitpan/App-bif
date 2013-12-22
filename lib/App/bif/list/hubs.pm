package App::bif::list::hubs;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_db;

    DBIx::ThinSQL->import(qw/ count /);

    my $data = $db->xarrays(
        select => [
            'hubs.id',       'hubs.alias',
            'hubs.location', count('links.topic_id')->as('link_count'),
        ],
        from      => 'hubs',
        left_join => 'links',
        on        => 'links.hub_id == hubs.id',
        group_by  => [ 'hubs.alias', 'hubs.location' ],
        order_by  => 'hubs.alias',
    );

    return [] unless @$data;

    start_pager( scalar @$data );

    print render_table( ' r  l  l  r ', [ 'ID', 'Alias', 'Location', 'Links' ],
        $data );

    end_pager;

    return $data;
}

1;
__END__

=head1 NAME

bif-list-hubs - list hubs associated with a repository

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif list hubs [OPTIONS...]

=head1 DESCRIPTION

Lists the hubs associated with a repository.

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

