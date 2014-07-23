package App::bif::show::entity;
use strict;
use warnings;
use App::bif::Context;
use App::bif::show;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    $ctx->{id} = $ctx->uuid2id( $ctx->{id} );

    App::bif::show::_init;

    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhash(
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
            'u.author',
            'u.email',
            'u.message',
            'e.local',
            'h.name AS hub_name',
            'hr.location AS hub_location'
        ],
        from       => 'entities e',
        inner_join => 'topics t',
        on         => 't.id = e.id',
        inner_join => 'updates u',
        on         => 'u.id = t.first_update_id',
        inner_join => 'entities c',
        on         => 'c.id = e.contact_id',
        inner_join => 'hubs h',
        on         => 'h.id = e.hub_id',
        inner_join => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        where      => { 'e.id' => $ctx->{id} },
    );

    return $ctx->err( 'EntityNotFound', "entity not found: $ctx->{id}" )
      unless $ref;

    my $bold = Term::ANSIColor::color('bold');

    push(
        @data,
        App::bif::show::_header( $bold . 'Entity', $bold . $ref->{name} ),
        App::bif::show::_header( '  UUID',         $ref->{uuid} ),
        App::bif::show::_header(
            '  Hub', $ref->{hub_name}, $ref->{hub_location}
        ),
        App::bif::show::_header(
            '  Updated',
            App::bif::show::_new_ago( $ref->{mtime}, $ref->{mtimetz} )
        ),
    );

    push( @data, App::bif::show::_header( '  Contact', $ref->{contact} ), )
      if $ref->{other_contact};

    my @methods = $db->xhashes(
        select => [
            'ecm.method', 'ecm.mvalue',
            'ecm.id = e.default_contact_method_id AS preferred',
        ],
        from       => 'entities e',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.entity_id = e.id',
        where      => { 'e.id' => $ctx->{id} },
        order_by   => [qw/ ecm.method ecm.mvalue /],
    );

    push(
        @data,
        App::bif::show::_header(
            '  '
              . ( $ref->{other_contact} ? '  ' : '' )
              . ucfirst( $_->{method} ),
            $_->{mvalue},
            $_->{preferred} ? 'preferred' : ()
        ),
    ) for @methods;

    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    $ctx->end_pager;

    return $ctx->ok( 'ShowEntity', \@data );
}

1;
__END__

=head1 NAME

bif-show-entity - display a entity's current status

=head1 VERSION

0.1.0_26 (2014-07-23)

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

=item --uuid, -u

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

