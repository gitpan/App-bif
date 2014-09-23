package App::bif::show::entity;
use strict;
use warnings;
use parent 'App::bif::show';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    $self->{id} = $self->uuid2id( $self->{id} );

    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhashref(
        select => [
            't.id',
            'substr(t.uuid,1,8) as uuid',
            'e.name',
            'c.contact_id != e.id AS other_contact',
            'c.name AS contact',
            't.ctime',
            't.ctimetz',
            't.mtime',
            't.mtimetz',
            'c.author',
            'c.email',
            'c.message',
            'e.local',
            'h.name AS hub_name',
            'hr.location AS hub_location'
        ],
        from       => 'entities e',
        inner_join => 'topics t',
        on         => 't.id = e.id',
        inner_join => 'changes c',
        on         => 'c.id = t.first_change_id',
        inner_join => 'entities c',
        on         => 'c.id = e.contact_id',
        inner_join => 'hubs h',
        on         => 'h.id = e.hub_id',
        inner_join => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        where      => { 'e.id' => $self->{id} },
    );

    return $self->err( 'EntityNotFound', "entity not found: $self->{id}" )
      unless $ref;

    $self->init;
    my ($bold) = $self->colours('bold');

    push(
        @data,
        $self->header( '  UUID', $ref->{uuid} ),
        $self->header( '  Hub', $ref->{hub_name}, $ref->{hub_location} ),
        $self->header(
            '  Updated', $self->ago( $ref->{mtime}, $ref->{mtimetz} )
        ),
    );

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

    $self->start_pager;
    print $self->render_table( 'l  l', $self->header( 'Entity', $ref->{name} ),
        \@data, 1 );
    $self->end_pager;

    return $self->ok( 'ShowEntity', \@data );
}

1;
__END__

=head1 NAME

bif-show-entity - display a entity's current status

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif show entity ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show entity> command displays the characteristics of an
entity.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An entity ID. Required.

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

