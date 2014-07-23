package App::bif::list::identities;
use strict;
use warnings;
use App::bif::Context;
use Term::ANSIColor 'color';

our $VERSION = '0.1.0_26';

sub run {
    my $ctx   = App::bif::Context->new(shift);
    my $db    = $ctx->db;
    my $dark  = color('dark');
    my $reset = color('reset');

    DBIx::ThinSQL->import(qw/ case qv /);

    my $data = $db->xarrays(
        select => [
            qv( $dark . 'identity' . $reset )->as('type'),
            'i.id', 'e.name',
            "ecm.mvalue || ' (' || ecm.method || ')' AS contact",
            case (
                when => 'ids.id = i.id',
                then => qv('*'),
                else => qv(''),
            )->as('self'),
        ],
        from       => 'identities i',
        inner_join => 'entities e',
        on         => 'e.id = i.id',
        inner_join => 'entities c',
        on         => 'c.id = e.contact_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        left_join  => 'identity_self ids',
        on         => 'ids.id = i.id',
        order_by   => [qw/e.name contact ecm.mvalue/],
    );

    return $ctx->ok('ListIdentities') unless @$data;

    $ctx->start_pager( scalar @$data );

    print $ctx->render_table( ' l r  l  l l ',
        [ 'Type', 'ID', 'Name', 'Contact (Method)', '' ], $data );

    $ctx->end_pager;

    return $ctx->ok('ListIdentities');
}

1;
__END__

=head1 NAME

bif-list-identities - list identities present in repository

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif list identities

=head1 DESCRIPTION

The C<bif list identities> command lists the identities present in the
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

