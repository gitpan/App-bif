package App::bif::list::hosts;
use strict;
use warnings;
use Bif::Mo;
use Term::ANSIColor 'color';

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self  = shift;
    my $opts  = $self->opts;
    my $db    = $self->db;
    my $dark  = color('yellow');
    my $reset = color('reset');

    DBIx::ThinSQL->import(qw/ case qv concat /);

    my $data = $db->xarrayrefs(
        select => [
            qv( $dark . 'host' . $reset )->as('type'),
            'h.id AS id',
            'h.name AS name',
            'e.name AS provider',
        ],
        from       => 'hosts h',
        inner_join => 'providers p',
        on         => 'p.id = h.provider_id',
        inner_join => 'entities e',
        on         => 'e.id = p.id',
        order_by   => [qw/provider name/],
    );

    return $self->ok('ListHostsNone') unless $data;

    $self->start_pager( scalar @$data );

    print $self->render_table( ' l r  l  l ',
        [ 'Type', 'ID', 'Name', 'Provider' ], $data );

    return $self->ok('ListHosts');
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-list-hosts - list hosts present in repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif list hosts

=head1 DESCRIPTION

The B<bif-list-hosts> command lists the provider hosts present in the
current repository.

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

