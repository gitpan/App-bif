package App::bif::list::hubs;
use strict;
use warnings;
use Bif::Mo;
use Term::ANSIColor qw/color/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    DBIx::ThinSQL->import(qw/ qv concat/);

    my $data = $db->xarrayrefs(
        select => [
            concat( qv( color('dark') ), 't.kind', qv( color('reset') ) )
              ->as('type'),
            'h.id',
            'COALESCE(h.name,"") AS hname',
            'COALESCE(hr.location,"") AS location',
            'COUNT(p.id)',
        ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        left_join  => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        left_join  => 'projects p',
        on         => 'p.hub_id = h.id',
        group_by =>
          [ 'h.id', 'COALESCE(h.name,"")', 'COALESCE(hr.location,"")', ],
        order_by => 'hname',
    );

    return $self->ok('ListHubs') unless $data;

    $self->start_pager( scalar @$data );

    print $self->render_table( ' l r  l  l  r ',
        [ 'Type', 'ID', 'Name', 'Location', 'Projects' ], $data );

    return $self->ok('ListHubs');
}

1;
__END__

=head1 NAME

=for bif-doc #list

bif-list-hubs - list hubs registered with current repository

=head1 VERSION

0.1.2 (2014-10-08)

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

