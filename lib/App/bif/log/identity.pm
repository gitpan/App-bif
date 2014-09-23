package App::bif::log::identity;
use strict;
use warnings;
use parent 'App::bif::log';

our $VERSION = '0.1.0_28';

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
            concat( qv('c'), 'c.id' )->as('change_id'),
            'SUBSTR(c.uuid,1,8) AS change_uuid',
            'c.mtime AS mtime',
            'c.mtimetz AS mtimetz',
            'c.action AS action',
            'COALESCE(c.author,e.name) AS author',
            'c.email AS email',
            'c.message AS message',
            'c.ucount AS ucount',
            qv(undef)->as('name'),
            qv(undef)->as('method'),
            qv(undef)->as('mvalue'),
            'c.path AS path',
            'ct.depth AS depth',
        ],
        from       => 'identity_deltas id',
        inner_join => 'changes c',
        on         => 'c.id = id.change_id',
        inner_join => 'entities e',
        on         => 'e.id = c.identity_id',
        inner_join => 'changes_tree ct',
        on         => {
            'ct.child' => \'c.id',
        },
        where            => { 'id.identity_id' => $info->{id}, },
        union_all_select => [
            'ed.id AS id',
            concat( qv('c'), 'c.id' )->as('change_id'),
            'SUBSTR(c.uuid,1,8) AS change_uuid',
            'c.mtime AS mtime',
            'c.mtimetz AS mtimetz',
            'c.action AS action',
            'COALESCE(c.author,e.name) AS author',
            'c.email AS email',
            'c.message AS message',
            'c.ucount AS ucount',
            'ed.name AS name',
            qv(undef)->as('method'),
            qv(undef)->as('mvalue'),
            'c.path AS path',
            'ct.depth AS depth',
        ],
        from       => 'entity_deltas ed',
        inner_join => 'changes c',
        on         => 'c.id = ed.change_id',
        inner_join => 'entities e',
        on         => 'e.id = c.identity_id',
        inner_join => 'changes_tree ct',
        on         => {
            'ct.child' => \'c.id',
        },
        where            => { 'ed.entity_id' => $info->{id}, },
        union_all_select => [
            'ecmd.id AS id',
            concat( qv('c'), 'c.id' )
              ->as('change_id'),
            'SUBSTR(c.uuid,1,8) AS change_uuid',
            'c.mtime',
            'c.mtimetz',
            'c.action',
            'COALESCE(c.author,e.name) AS author',
            'c.email',
            'c.message',
            'c.ucount',
            qv(undef),    # 'ecmd.name',
            'ecmd.method',
            'ecmd.mvalue',
            'c.path',
            'ct.depth',
        ],
        from       => 'entity_contact_methods ecm',
        inner_join => 'entity_contact_method_deltas ecmd',
        on         => 'ecmd.entity_contact_method_id = ecm.id',
        inner_join => 'changes c',
        on         => 'c.id = ecmd.change_id',
        inner_join => 'entities e',
        on         => 'e.id = c.identity_id',
        inner_join => 'changes_tree ct',
        on         => {
            'ct.child' => \'c.id',
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
                      . ( $row->{depth} > 1 ? 'reply' : 'change' ),
                    $dark . $yellow . $row->{change_id},
                    $row->{change_uuid}
                ),
            );
        }
        else {
            $row->{change_id} =~ s/(.+)\./$yellow$1$dark\./;

            push(
                @data,
                $self->header(
                    $yellow . 'identity',
                    $row->{change_id},
                    substr( $info->{uuid}, 0, 8 ) . '.' . $row->{change_uuid}
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

0.1.0_28 (2014-09-23)

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

