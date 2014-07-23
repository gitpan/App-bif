package App::bif::log::identity;
use strict;
use warnings;
use App::bif::Context;
use App::bif::log;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx  = App::bif::Context->new(shift);
    my $db   = $ctx->db;
    my $info = $ctx->get_topic( $ctx->{id} );

    return $ctx->err( 'TopicNotFound', "topic not found: $ctx->{id}" )
      unless $info;

    return $ctx->err( 'NotAnIdentity', "not an identity ID: $ctx->{id}" )
      unless $info->{kind} eq 'identity';

    App::bif::log::init;
    my $dark   = $App::bif::log::dark;
    my $reset  = $App::bif::log::reset;
    my $yellow = $App::bif::log::yellow;

    DBIx::ThinSQL->import(qw/concat case qv/);
    my $sth = $db->xprepare(
        select => [
            'id.id AS id',
            concat( 'id.identity_id', qv('.'), 'u.id' )->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime AS mtime',
            'u.mtimetz AS mtimetz',
            'u.author AS author',
            'u.email AS email',
            'u.message AS message',
            'u.ucount AS ucount',
            'id.new AS new',
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
            concat( 'ed.entity_id', qv('.'), 'u.id' )->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime AS mtime',
            'u.mtimetz AS mtimetz',
            'u.author AS author',
            'u.email AS email',
            'u.message AS message',
            'u.ucount AS ucount',
            'ed.new AS new',
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
            concat( 'ecm.id', qv('.'), 'u.id' )
              ->as('update_id'),
            'SUBSTR(u.uuid,1,8) AS update_uuid',
            'u.mtime',
            'u.mtimetz',
            'u.author',
            'u.email',
            'u.message',
            'u.ucount',
            'ecmd.new',
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

    $ctx->start_pager;
    my $name;
    my $i = 0;

    while ( my $row = $sth->hash ) {

        $name = $row->{name} if $row->{name};
        my @mvs;
        push( @mvs, [ $row->{method}, $row->{mvalue} ] )
          if defined $row->{method};

        my @data;
        if ( $i++ ) {
            push(
                @data,
                App::bif::log::_header(
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
                App::bif::log::_header(
                    $yellow . 'identity',
                    $row->{update_id},
                    substr( $info->{uuid}, 0, 8 ) . '.' . $row->{update_uuid}
                ),
            );
        }

        push(
            @data,
            App::bif::log::_header( 'From', $row->{author}, $row->{email} ),
            App::bif::log::_header(
                'When',
                App::bif::log::_new_ago( $row->{mtime}, $row->{mtimetz} )
            ),
        );

        for my $i ( 1 .. ( $row->{ucount} - 2 ) ) {
            my $r = $sth->hash;
            $name = $r->{name} if $r->{name};
            push( @mvs, [ $r->{method}, $r->{mvalue} ] )
              if defined $r->{method};
        }

        push( @data, App::bif::log::_header( 'Subject', "$name" ) );

        push( @data, App::bif::log::_header( ucfirst( $_->[0] ), $_->[1] ) )
          for @mvs;

        print $ctx->render_table( 'l  l', undef, \@data,
            4 * ( $row->{depth} - 1 ) )
          . "\n";

        print App::bif::log::_reformat( $row->{message}, $row->{depth} ), "\n";

    }

    $ctx->end_pager;
    return $ctx->ok('LogIdentity');
}

1;
__END__

=head1 NAME

bif-log-identity - review the history of a identity

=head1 VERSION

0.1.0_26 (2014-07-23)

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

