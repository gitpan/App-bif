package App::bif::show::change;
use strict;
use warnings;
use App::bif::log;
use Bif::Mo;
use DBIx::ThinSQL qw/sq qv/;

our $VERSION = '0.1.4';
extends 'App::bif::show';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;
    my $info = $self->get_change( $opts->{uid} );
    my $now  = $self->now;

    my $ref = $dbw->xhashref(
        select => [
            'c.id',
            'c.mtime AS mtime',
            'c.mtimetz AS mtimetz',
            'c.mtimetzhm AS mtimetzhm',
            "$now - c.mtime AS mtime_age",
            'c.uuid AS uuid',
            'c.action',
            'e.name',
            'COALESCE(c.author,e.name) AS author',
            'COALESCE(c.email,ecm.mvalue) AS email',
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
        where      => { 'c.id' => $info->{id} },
    );

    # YAML::Tiny only installed by cpanm --with-develop
    my $yaml    = '';
    my $invalid = '';

    if ( eval { require YAML::Tiny } ) {
        require Bif::DB::Plugin::Changes;
        require Digest::SHA;

        my $sth = $dbw->xprepare_changeset_ext(
            with => 'src',
            as   => sq(
                select => qv( $info->{id} )->as('id'),
            ),
        );

        $sth->execute;
        my $ref2 = $sth->changeset_ext;
        delete $ref2->[0]->{uuid};

        $yaml = YAML::Tiny::Dump($ref2);
        my ( $green, $red, $reset ) = $self->colours(qw/green red reset/);

        $invalid =
          Digest::SHA::sha1_hex($yaml) eq $ref->{uuid}
          ? ' (' . $green . 'VALID' . $reset . ')'
          : ' (' . $red . 'INVALID!' . $reset . ')';
    }

    my @data;
    push( @data,
        $self->header( '  From', $ref->{author}, $ref->{email} ),
        $self->header( '  When', $self->mtime_ago($ref) ),
        $self->header( '  UUID', $ref->{uuid} . $invalid ),
    );

    $self->start_pager;

    print $self->render_table( 'l  l',
        [ 'a' . $ref->{id} . ':', $ref->{action} ],
        \@data, 1 );

    print "\n";
    print App::bif::log->reformat( $ref->{message} );

    ( my $x = $yaml ) =~ s/^/ /mg;
    print $x;

    return $self->ok('ShowChange');
}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show-change - show change information

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif show change ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-change> command displays information about an action in
the repository, similar to how each change is displayed by L<bif-log>
commands. This command is likely only useful for developers.

If the L<YAML::Tiny> module is installed then B<bif-show-change> also
displays the change as a YAML document and reports on whether the UUID
is valid or not.

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

