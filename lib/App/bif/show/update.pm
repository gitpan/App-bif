package App::bif::show::update;
use strict;
use warnings;
use feature 'say';
use lib 'lib';
use parent 'App::bif::Context';
use DBIx::ThinSQL qw/case qi qv/;
use Digest::SHA qw/sha1_hex/;
use YAML qw/Dump/;

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_update( $self->{uid} );

    my $u = $db->xhashref(
        select => [
            'u.author',
            'u.email',
            case (
                when => 'i.first_update_id = u.id',
                then => 'NULL',
                else => 'i.uuid',
              )->as('identity_uuid'),
            'u.lang',
            'u.message',
            'u.mtime',
            'u.mtimetz',
            'p.uuid AS parent_uuid',
            'u.uuid',
        ],
        from       => 'updates u',
        left_join  => 'updates p',
        on         => 'p.id = u.parent_id',
        inner_join => 'topics i',
        on         => 'i.id = u.identity_id',
        where      => { 'u.id' => $info->{id} },
    );

    my $uuid = delete $u->{uuid};
    my @deltas;

    my @update_deltas = $db->xhashrefs(
        select => [
            qv('update_delta')->as('action'),
            'ud.id',
            'ud.action_format',
            't1.uuid AS action_topic_uuid_1',
            't2.uuid AS action_topic_uuid_2',
        ],
        from      => 'update_deltas ud',
        left_join => 'topics t1',
        on        => 't1.id = ud.action_topic_id_1',
        left_join => 'topics t2',
        on        => 't2.id = ud.action_topic_id_2',
        where     => { 'ud.update_id' => $info->{id} },
    );

    push( @deltas, @update_deltas );

    my @topics = $db->xhashrefs(
        select =>
          [ qv('topic')->as('action'), 't.kind', 't.update_order AS id' ],
        from  => 'topics t',
        where => { 't.first_update_id' => $info->{id} },
    );

    push( @deltas, @topics );

    my @ids = $db->xhashrefs(
        select =>
          [ qv('identity')->as('action'), 'id.id', 't.uuid AS topic_uuid', ],
        from       => 'identity_deltas id',
        inner_join => 'topics t',
        on         => 't.id = id.identity_id',
        where      => { 'id.update_id' => $info->{id}, 'id.new' => 1, },
    );

    push( @deltas, @ids );

    my @id_deltas = $db->xhashrefs(
        select => [
            qv('identity_delta')->as('action'), 'id.id',
            'i.uuid AS identity_uuid',
        ],
        from       => 'identity_deltas id',
        inner_join => 'topics i',
        on         => 'i.id = id.identity_id',
        where      => {
            'id.update_id' => $info->{id},
            'id.new'       => undef,
        },
    );

    push( @deltas, @id_deltas );

    my @entities = $db->xhashrefs(
        select => [
            qv('entity')->as('action'),
            'ed.id',
            'c.uuid AS contact_uuid',
            'ecm.uuid AS default_contact_method_uuid',
            't.uuid AS topic_uuid',
            'ed.name'
        ],
        from       => 'entity_deltas ed',
        inner_join => 'topics t',
        on         => 't.id = ed.entity_id',
        left_join  => 'topics c',
        on         => 'c.id = ed.contact_id',
        left_join  => 'topics ecm',
        on         => 'ecm.id = ed.default_contact_method_id',
        where      => { 'ed.update_id' => $info->{id}, 'ed.new' => 1, },
    );

    push( @deltas, @entities );

    my @entity_deltas = $db->xhashrefs(
        select => [
            qv('entity_delta')->as('action'),
            'ed.id',
            'c.uuid AS contact_uuid',
            'ecm.uuid AS default_contact_method_uuid',
            'e.uuid AS entity_uuid',
            'ed.name'
        ],
        from       => 'entity_deltas ed',
        inner_join => 'topics e',
        on         => 'e.id = ed.entity_id',
        left_join  => 'topics c',
        on         => 'c.id = ed.contact_id',
        left_join  => 'topics ecm',
        on         => 'ecm.id = ed.default_contact_method_id',
        where      => {
            'ed.update_id' => $info->{id},
            'ed.new'       => undef,
        },
    );

    push( @deltas, @entity_deltas );

    my @ecm = $db->xhashrefs(
        select => [
            qv('entity_contact_method')->as('action'), 'ecmd.id',
            't.uuid AS topic_uuid',                    'ecmd.method',
            'ecmd.mvalue',
        ],
        from       => 'entity_contact_method_deltas ecmd',
        inner_join => 'topics t',
        on         => 't.id = ecmd.entity_contact_method_id',
        where      => {
            'ecmd.update_id' => $info->{id},
            'ecmd.new'       => 1,
        },
    );

    push( @deltas, @ecm );

    my @ecmd = $db->xhashrefs(
        select => [
            qv('entity_contact_method_delta')->as('action'), 'ecmd.id',
            'ecm.uuid AS entity_contact_method_uuid',        'ecmd.method',
            'ecmd.mvalue',
        ],
        from       => 'entity_contact_method_deltas ecmd',
        inner_join => 'topics ecm',
        on         => 'ecm.id = ecmd.entity_contact_method_id',
        where      => {
            'ecmd.update_id' => $info->{id},
            'ecmd.new'       => undef,
        },
    );

    push( @deltas, @ecmd );

    my @hubs = $db->xhashrefs(
        select => [
            qv('hub')->as('action'), 'hd.id',
            'hd.name',               'p.uuid AS project_uuid',
            't.uuid AS topic_uuid',
        ],
        from       => 'hub_deltas hd',
        inner_join => 'topics t',
        on         => 't.id = hd.hub_id',
        left_join  => 'topics p',
        on         => 'p.id = hd.project_id',
        where      => { 'hd.update_id' => $info->{id} },
    );

    push( @deltas, @hubs );

    my @hub_deltas = $db->xhashrefs(
        select => [
            qv('hub_delta')->as('action'), 'hd.id',
            'hd.name',                     'p.uuid AS project_uuid',
            'h.uuid AS hub_uuid',
        ],
        from       => 'hub_deltas hd',
        inner_join => 'topics h',
        on         => 'h.id = hd.hub_id',
        left_join  => 'topics p',
        on         => 'p.id = hd.project_id',
        where      => {
            'hd.update_id' => $info->{id},
            'hd.new'       => undef,
        },
    );

    push( @deltas, @hub_deltas );

    my @hub_repos = $db->xhashrefs(
        select => [
            qv('hub_repo')->as('action'), 'hrd.id',
            't.uuid AS topic_uuid',       'h.uuid AS hub_uuid',
            'hrd.location',
        ],
        from       => 'hub_repo_deltas hrd',
        inner_join => 'topics t',
        on         => 't.id = hrd.hub_repo_id',
        inner_join => 'topics h',
        on         => 'h.id = hrd.hub_id',
        where      => { 'hrd.update_id' => $info->{id} },
    );

    push( @deltas, @hub_repos );

    my @hub_repo_deltas = $db->xhashrefs(
        select => [
            qv('hub_repo_delta')->as('action'), 'hrd.id',
            'hr.uuid AS hub_repo_uuid',         'h.uuid AS hub_uuid',
            'hrd.location',
        ],
        from       => 'hub_repo_deltas hrd',
        inner_join => 'topics hr',
        on         => 'hr.id = hrd.hub_repo_id',
        inner_join => 'topics h',
        on         => 'h.id = hrd.hub_id',
        where      => {
            'hrd.update_id' => $info->{id},
            'hrd.new'       => undef,
        },
    );

    push( @deltas, @hub_repo_deltas );

    foreach my $d ( sort { $a->{id} <=> $b->{id} } @deltas ) {
        delete $d->{id};
        my $action = delete $d->{action};
        push( @{ $u->{zdeltas} }, { $action => $d } );
    }

    print "# $self->{uid} ($uuid)\n";

    my $yaml = Dump($u);
    my $sha1 = sha1_hex($yaml);

    if ( $uuid eq $sha1 ) {
        print $yaml;
        return $self->ok('ShowUpdate');
    }
    else {
        # TODO this is a development aide that will stop working when
        # we start deleting from updates_pending again.
        my $terms = $db->xval(
            select => 'up.terms',
            from   => 'updates_pending up',
            where  => { 'up.update_id' => $info->{id} },
        );
        require Data::Dumper;
        require String::Diff;

        my ( $del, $add, $reset ) = $self->colours( 'red', 'green', 'reset' );
        print scalar String::Diff::diff_merge(
            $yaml, $terms,
            $self->{_bif_terminal}
            ? (
                remove_open  => $del,
                remove_close => $reset,
                append_open  => $add,
                append_close => $reset,
              )
            : ()
        );

        return $self->err( 'UUIDMismatch', "UUID mismatch (got %s)", $sha1 );
    }
}

1;
__END__

=head1 NAME

bif-show-update - show an update's deltas as YAML

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif show update ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show update> command prints the deltas that make up an update
in YAML format. It will raise an error if the SHA1 hash of the YAML and
the update UUID do not match.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

The integer ID of an update.

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

