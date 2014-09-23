package App::bif::list::entities;
use strict;
use warnings;
use parent 'App::bif::Context';
use Term::ANSIColor 'color';

our $VERSION = '0.1.0_28';

sub run {
    my $self  = __PACKAGE__->new(shift);
    my $db    = $self->db;
    my $dark  = color('dark');
    my $reset = color('reset');

    DBIx::ThinSQL->import(qw/ concat case qv /);

    my $data = $db->xarrayrefs(
        select => [
            concat( qv($dark), 't.kind', qv($reset) )->as('type'),
            'e.id', 'e.name',
            "ecm.mvalue || ' (' || ecm.method || ')' AS contact",
            case (
                when => 'e.contact_id != e.id',
                then => 'c.name',
                else => qv('-'),
            )->as('via'),
        ],
        from       => 'entities e',
        inner_join => 'topics t',
        on         => 't.id = e.id',
        inner_join => 'entities c',
        on         => 'c.id = e.contact_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        order_by   => [qw/e.name contact ecm.mvalue/],
    );

    return $self->ok('ListEntities') unless @$data;

    $self->start_pager( scalar @$data );

    print $self->render_table( ' l r  l  l  l ',
        [ 'Type', 'ID', 'Entity', 'Contact (Method)', 'Via' ], $data );

    $self->end_pager;

    return $self->ok('ListEntities');
}

1;
__END__

=head1 NAME

bif-list-entities - list entities present in repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif list entities

=head1 DESCRIPTION

The C<bif list entities> command lists the entities present in the
current repository.

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

