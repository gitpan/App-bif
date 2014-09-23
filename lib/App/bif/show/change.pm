package App::bif::show::change;
use strict;
use warnings;
use parent 'App::bif::show';
use DBIx::ThinSQL qw/sq qv/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $dbw  = $self->dbw;
    my $info = $self->get_change( $self->{uid} );

    my $ref = $dbw->xhashref(
        select => [
            'c.id',
            'c.mtime',
            'c.mtimetz',
            'SUBSTR(c.uuid,1,8) AS uuid',
            'c.action',
            'e.name',
            'COALESCE(c.author,e.name) AS author',
            'COALESCE(c.email,ecm.mvalue) AS email',
            't.id AS topic_id',
            't.kind',
            'c.message',
        ],
        from       => 'changes c',
        inner_join => 'identities id',
        on         => 'id.id = c.identity_id',
        inner_join => 'entities e',
        on         => 'e.id = c.identity_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        left_join  => 'change_deltas cd',
        on         => 'cd.change_id = c.id',
        left_join  => 'topics t',
        on         => 't.id = cd.action_topic_id_1',
        where      => { 'c.id' => $info->{id} },
    );

    $self->init;

    my @data;
    push( @data,
        $self->header( '  UUID', $ref->{uuid},              '' ),
        $self->header( '  From', $ref->{author},            $ref->{email} ),
        $self->header( '  When', $self->ago( $ref->{mtime}, $ref->{mtimetz} ) ),
        $self->header( '  Topic',   "$ref->{kind} $ref->{topic_id}", ),
        $self->header( '  Message', $ref->{message} ),
    );

    $self->start_pager;

    print $self->render_table( 'l  l',
        [ 'Change ' . $ref->{id}, $ref->{action} ],
        \@data, 1 );

    $self->end_pager;

    return $self->ok('ShowChange');
}

1;
__END__

=head1 NAME

bif-show-change - show change information

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif show change ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-change> command displays information about an action in
the repository. This command has possibly no purpose, but is a leftover
from development activities.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

The integer ID of an change.

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

