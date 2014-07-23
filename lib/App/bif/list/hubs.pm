package App::bif::list::hubs;
use strict;
use warnings;
use App::bif::Context;
use Term::ANSIColor qw/color/;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    DBIx::ThinSQL->import(qw/ count qv/);

    my $data = $db->xarrays(
        select => [
            qv( color('dark') . 'hub' . color('reset') )->as('type'),
            'COALESCE(h.name,"") AS hname',
            'hr.location', 'COUNT(p.id)',
        ],
        from       => 'hubs h',
        inner_join => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        left_join  => 'projects p',
        on         => 'p.hub_id = h.id',
        group_by   => [ 'h.id', 'hname', 'hr.location' ],
        order_by   => 'hname',
    );

    return $ctx->ok('ListHubs') unless @$data;

    $ctx->start_pager( scalar @$data );

    print $ctx->render_table( ' l l  l  r ',
        [ 'Type', 'Name', 'Location', 'Projects' ], $data );

    $ctx->end_pager;

    return $ctx->ok('ListHubs');
}

1;
__END__

=head1 NAME

bif-list-hubs - list hubs registered with current repository

=head1 VERSION

0.1.0_26 (2014-07-23)

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

