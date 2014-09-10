package App::bif::log::identity;
use strict;
use warnings;
use parent 'App::bif::log';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_topic( $self->{id} );

    return $self->err( 'TopicNotFound', "topic not found: $self->{id}" )
      unless $info;

    return $self->err( 'NotAnIdentity', "not an identity ID: $self->{id}" )
      unless $info->{kind} eq 'identity';

    $self->init;

    my ( $dark, $reset, $yellow ) = $self->colours(qw/dark reset yellow/);

    DBIx::ThinSQL->import(qw/concat case qv/);
    my $sth = $db->xprepare(
        select => [
            'id.id AS id',
            concat( qv('u'), 'u.id' )->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime AS mtime',
            'u.mtimetz AS mtimetz',
            'u.action AS action',
            'u.author AS author',
            'u.email AS email',
            'u.message AS message',
            'u.ucount AS ucount',
            qv(undef)->as('name'),
            qv(undef)->as('method'),
            qv(undef)->as('mvalue'),
            'u.path AS path',
            'ut.depth AS depth',
        ],
        from       => 'identity_deltas id',
        inner_join => 'updates u',
        on         => 'u.id = id.update_id',
        inner_join => 'updates_tree ut',
        on         => {
            'ut.child' => \'u.id',
        },
        where            => { 'id.identity_id' => $info->{id}, },
        union_all_select => [
            'ed.id AS id',
            concat( qv('u'), 'u.id' )->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime AS mtime',
            'u.mtimetz AS mtimetz',
            'u.action AS action',
            'u.author AS author',
            'u.email AS email',
            'u.message AS message',
            'u.ucount AS ucount',
            'ed.name AS name',
            qv(undef)->as('method'),
            qv(undef)->as('mvalue'),
            'u.path AS path',
            'ut.depth AS depth',
        ],
        from       => 'entity_deltas ed',
        inner_join => 'updates u',
        on         => 'u.id = ed.update_id',
        inner_join => 'updates_tree ut',
        on         => {
            'ut.child' => \'u.id',
        },
        where            => { 'ed.entity_id' => $info->{id}, },
        union_all_select => [
            'ecmd.id AS id',
            concat( qv('u'), 'u.id' )
              ->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime',
            'u.mtimetz',
            'u.action',
            'u.author',
            'u.email',
            'u.message',
            'u.ucount',
            qv(undef),    # 'ecmd.name',
            'ecmd.method',
            'ecmd.mvalue',
            'u.path',
            'ut.depth',
        ],
        from       => 'entity_contact_methods ecm',
        inner_join => 'entity_contact_method_deltas ecmd',
        on         => 'ecmd.entity_contact_method_id = ecm.id',
        inner_join => 'updates u',
        on         => 'u.id = ecmd.update_id',
        inner_join => 'updates_tree ut',
        on         => {
            'ut.child' => \'u.id',
        },
        where => { 'ecm.entity_id' => $info->{id}, },
        order_by => [ 'path ASC', 'id' ],
    );

    $sth->execute;

    $self->start_pager;
    my $name;
    my $i = 0;

    while ( my $row = $sth->hashref ) {

        $name = $row->{name} if $row->{name};
        my @mvs;
        push( @mvs, [ $row->{method}, $row->{mvalue} ] )
          if defined $row->{method};

        my @data;
        if ( $i++ ) {
            push(
                @data,
                $self->header(
                    $dark
                      . $yellow
                      . ( $row->{depth} > 1 ? 'reply' : 'update' ),
                    $dark . $yellow . $row->{update_id},
                    $row->{update_uuid}
                ),
            );
        }
        else {
            $row->{update_id} =~ s/(.+)\./$yellow$1$dark\./;

            push(
                @data,
                $self->header(
                    $yellow . 'identity',
                    $row->{update_id},
                    substr( $info->{uuid}, 0, 8 ) . '.' . $row->{update_uuid}
                ),
            );
        }

        push(
            @data,
            $self->header( 'From', $row->{author}, $row->{email} ),
            $self->header(
                'When', $self->ago( $row->{mtime}, $row->{mtimetz} )
            ),
        );

        for my $i ( 1 .. ( $row->{ucount} - 2 ) ) {
            my $r = $sth->hashref;
            $name = $r->{name} if $r->{name};
            push( @mvs, [ $r->{method}, $r->{mvalue} ] )
              if defined $r->{method};
        }

        push( @data, $self->header( 'Subject', "$name" ) );

        push( @data, $self->header( ucfirst( $_->[0] ), $_->[1] ) ) for @mvs;

        print $self->render_table( 'l  l', undef, \@data,
            4 * ( $row->{depth} - 1 ) )
          . "\n";

        print $self->reformat( $row->{message}, $row->{depth} ), "\n";

    }

    $self->end_pager;
    return $self->ok('LogIdentity');
}

1;
__END__

=head1 NAME

bif-log-identity - review the history of a identity

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log identity ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif log identity> command displays the history of an identity.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

The ID of a identity. Required.

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

