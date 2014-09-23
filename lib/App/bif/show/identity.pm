package App::bif::show::identity;
use strict;
use warnings;
use parent 'App::bif::show';
use DBIx::ThinSQL qw/sum case coalesce concat qv/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;

    $self->{id} = $self->uuid2id( $self->{id} );

    $self->init;

    my @data;

    my $ref = $db->xhashref(
        select => [
            'i.id',               'substr(t.uuid,1,8) as uuid',
            'e.name',             'ct.contact_id != e.id AS other_contact',
            'ct.name AS contact', 't.ctime',
            't.ctimetz',          't.mtime',
            't.mtimetz',          'c.author',
            'c.email',            'c.message',
            'e.local',
        ],
        from       => 'identities i',
        inner_join => 'entities e',
        on         => 'e.id = i.id',
        inner_join => 'topics t',
        on         => 't.id = i.id',
        inner_join => 'changes c',
        on         => 'c.id = t.first_change_id',
        inner_join => 'entities ct',
        on         => 'ct.id = e.contact_id',
        where      => { 'i.id' => $self->{id} },
    );

    return $self->err( 'IdentityNotFound', "identity not found: $self->{id}" )
      unless $ref;

    my ($bold) = $self->colours('bold');

    push( @data, $self->header( '  UUID', $ref->{uuid} ), );

    push( @data, $self->header( '  Contact', $ref->{contact} ), )
      if $ref->{other_contact};

    my @methods = $db->xhashrefs(
        select => [
            'ecm.method', 'ecm.mvalue',
            'ecm.id = e.default_contact_method_id AS preferred',
        ],
        from       => 'entities e',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.entity_id = e.id',
        where      => { 'e.id' => $self->{id} },
        order_by   => [qw/ ecm.method ecm.mvalue /],
    );

    push(
        @data,
        $self->header(
            '  '
              . ( $ref->{other_contact} ? '  ' : '' )
              . ucfirst( $_->{method} ),
            $_->{mvalue},
            $_->{preferred} ? 'preferred' : ()
        ),
    ) for @methods;

    push(
        @data,
        $self->header(
            '  Updated', $self->ago( $ref->{mtime}, $ref->{mtimetz} )
        ),
    );

    $self->start_pager;
    print $self->render_table( 'l  l',
        $self->header( 'Identity', $ref->{name} ),
        \@data, 1 );
    $self->end_pager;

    return $self->ok( 'ShowIdentity', \@data );
}

1;
__END__

=head1 NAME

bif-show-identity - display a identity's current status

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif show identity ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show identity> command displays the characteristics of an
identity.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An identity ID. Required.

=item --full, -f

Display a more verbose version of the current status.

=item --uuid, -U

Lookup the topic using ID as a UUID string instead of a topic integer.

=back

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

