package App::bif::list::hubs;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_10';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    DBIx::ThinSQL->import(qw/ count /);

    my $data = $db->xarrays(
        select => [
            'r.id',        'COALESCE(r.alias,"") AS alias',
            'rl.location', 'COUNT(p.id)',
        ],
        from       => 'repos r',
        inner_join => 'repo_locations rl',
        on         => 'rl.id = r.default_location_id AND r.local IS NULL',
        left_join  => 'projects p',
        on         => 'p.repo_id = r.id',
        group_by   => [ 'r.id', 'alias', 'rl.location' ],
        order_by   => 'r.alias',
    );

    return $ctx->ok('ListHubs') unless @$data;

    $ctx->start_pager( scalar @$data );

    print $ctx->render_table( ' r  l  l  r ',
        [ 'ID', 'Alias', 'Location', 'Projects' ], $data );

    $ctx->end_pager;

    return $ctx->ok('ListHubs');
}

1;
__END__

=head1 NAME

bif-list-hubs - list hubs registered with current repository

=head1 VERSION

0.1.0_10 (2014-04-17)

=head1 SYNOPSIS

    bif list hubs

=head1 DESCRIPTION

Lists the hubs associated with the current repository.

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
