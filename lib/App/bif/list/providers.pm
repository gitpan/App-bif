package App::bif::list::providers;
use strict;
use warnings;
use parent 'App::bif::Context';
use Term::ANSIColor 'color';

our $VERSION = '0.1.0_27';

sub run {
    my $self  = __PACKAGE__->new(shift);
    my $db    = $self->db;
    my $dark  = color('dark');
    my $reset = color('reset');

    DBIx::ThinSQL->import(qw/ case qv sum sq/);

    my $data = $db->xarrayrefs(
        select => [
            qv( $dark . 'provider' . $reset )->as('type'),
            'e.name',
            "ecm.mvalue || ' (' || ecm.method || ')' AS contact",
            'COALESCE(pl.plans,0) AS plans',
            'COALESCE(h.hosts,0) AS hosts',
        ],
        from       => 'providers p',
        inner_join => 'entities e',
        on         => 'e.id = p.id',
        inner_join => 'entities c',
        on         => 'c.id = e.contact_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        left_join  => sq(
            select   => [ 'pl.provider_id', 'COUNT(pl.id) AS plans' ],
            from     => 'plans pl',
            group_by => 'pl.provider_id',
          )->as('pl'),
        on        => 'pl.provider_id = p.id',
        left_join => sq(
            select   => [ 'h.provider_id', 'COUNT(h.id) AS hosts' ],
            from     => 'hosts h',
            group_by => 'h.provider_id',
          )->as('h'),
        on       => 'h.provider_id = p.id',
        order_by => [qw/e.name contact ecm.mvalue/],
    );

    return $self->ok('ListProvidersNone') unless $data;

    $self->start_pager( scalar @$data );

    print $self->render_table( ' l  l  l  r  r ',
        [ 'Type', 'Name', 'Contact (Method)', 'Plans', 'Hosts' ], $data );

    $self->end_pager;

    return $self->ok('ListProviders');
}

1;
__END__

=head1 NAME

bifhub-list-providers - list providers present in repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bifhub list providers

=head1 DESCRIPTION

The C<bifhub list providers> command lists the providers present in the
current repository.

=head1 SEE ALSO

L<bifhub>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

