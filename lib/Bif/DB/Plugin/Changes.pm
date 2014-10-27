package Bif::DB::Plugin::Changes;
use strict;
use warnings;
use DBIx::ThinSQL qw/case qv/;

our $VERSION = '0.1.4';

sub Bif::DB::db::xprepare_changeset_ext {
    my $self = shift;

    return $self->xprepare(
        @_,

        # change
        select => [
            qv('change'),    # 0
            'c.uuid',        # 1
            'p.uuid',        # 2
            'i.uuid',        # 3
            'c.mtime',       # 4
            'c.mtimetz',     # 5
            'c.author',      # 6
            'c.email',       # 7
            'c.lang',        # 8
            'c.message',     # 9
            'c.ucount',      # 10
            'c.delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'changes c',
        on         => 'c.id = src.id',
        left_join  => 'topics i',

        # Don't fetch the identity_uuid for the first identity
        # change
        on        => 'i.id = c.identity_id AND i.first_change_id != c.id',
        left_join => 'changes p',
        on        => 'p.id = c.parent_id',

        # change_deltas
        union_all_select => [
            qv('change_delta'),    # 0
            't1.uuid',             # 1
            't2.uuid',             # 2
            'cd.action_format',    # 3
            4, 5, 6, 7, 8, 9, 10,
            'cd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'change_deltas cd',
        on         => 'cd.change_id = src.id',
        left_join  => 'topics t1',
        on         => 't1.id = cd.action_topic_id_1',
        left_join  => 'topics t2',
        on         => 't2.id = cd.action_topic_id_2',

        # entities
        union_all_select => [
            case (
                when => 'ed.new',
                then => qv('entity'),
                else => qv('entity_delta'),
            ),            # 0
            't.uuid',     # 1
            'ed.name',    # 2
            't2.uuid',    # 3
            't3.uuid',    # 4
            5, 6, 7, 8, 9, 10,
            'ed.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'entity_deltas ed',
        on         => 'ed.change_id = src.id',
        inner_join => 'topics t',
        on         => 't.id = ed.entity_id',
        left_join  => 'topics t2',
        on         => 't2.id = ed.contact_id',
        left_join  => 'topics t3',
        on         => 't3.id = ed.default_contact_method_id',

        # entity_contact_methods
        union_all_select => [
            case (
                when => 'ecmd.new',
                then => qv('entity_contact_method'),
                else => qv('entity_contact_method_delta'),
            ),                # 0
            't.uuid',         # 1
            'ecmd.method',    # 2
            'ecmd.mvalue',    # 3
            't2.uuid',        # 4
            5, 6, 7, 8, 9, 10,
            'ecmd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'entity_contact_method_deltas ecmd',
        on         => 'ecmd.change_id = src.id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = ecmd.entity_contact_method_id',
        inner_join => 'topics t',
        on         => 't.id = ecm.id',
        inner_join => 'topics t2',
        on         => 't2.id = ecm.entity_id',

        # hubs
        union_all_select => [
            case (
                when => 'hd.new',
                then => qv('hub'),
                else => qv('hub_delta'),
            ),            # 0
            't.uuid',     # 1
            'hd.name',    # 2
            3, 4, 5, 6, 7, 8,
            9, 10,
            'hd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'hub_deltas hd',
        on         => 'hd.change_id = src.id',
        inner_join => 'topics t',
        on         => 't.id = hd.hub_id',

        # hub_repos
        union_all_select => [
            case (
                when => 'hrd.new',
                then => qv('hub_repo'),
                else => qv('hub_repo_delta'),
            ),                 # 0
            't.uuid',          # 1
            'h.uuid',          # 2
            'hrd.location',    # 3
            4, 5, 6, 7, 8, 9,
            10,
            'hrd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'hub_repo_deltas hrd',
        on         => 'hrd.change_id = src.id',
        inner_join => 'topics t',
        on         => 't.id = hrd.hub_repo_id',
        inner_join => 'hub_repos hr',
        on         => 'hr.id = hrd.hub_repo_id',
        left_join  => 'topics h',
        on         => 'h.id = hr.hub_id',

        # identities
        union_all_select => [
            case (
                when => 'id.new',
                then => qv('identity'),
                else => qv('identity_delta'),
            ),                 # 0
            't.uuid',          # 1
            'id.shortname',    # 2
            3, 4, 5, 6, 7, 8,
            9, 10,
            'id.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'identity_deltas id',
        on         => 'id.change_id = src.id',
        inner_join => 'changes c',
        on         => 'c.id = id.change_id',
        inner_join => 'topics t',
        on         => 't.id = id.identity_id',

        # issue_status
        union_all_select => [
            case (
                when => 'isd.new',
                then => qv('issue_status'),
                else => qv('issue_status_delta'),
            ),               # 0
            't.uuid',        # 1
            'p.uuid',        # 2
            'isd.status',    # 3
            'isd.def',       # 4
            'isd.rank',      # 5
            6, 7, 8, 9, 10,
            'isd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'issue_status_deltas isd',
        on         => 'isd.change_id = src.id',
        left_join  => 'issue_status ist',
        on         => 'ist.id = isd.issue_status_id',
        inner_join => 'topics t',
        on         => 't.id = ist.id',
        inner_join => 'topics p',
        on         => 'p.id = ist.project_id',

        # issues
        union_all_select => [
            case (
                when => 'id.new',
                then => qv('issue'),
                else => qv('issue_delta'),
            ),             # 0
            't.uuid',      # 1
            'ist.uuid',    # 2
            'p.uuid',      # 3
            'id.title',    # 4
            5, 6, 7, 8, 9, 10,
            'id.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'issue_deltas id',
        on         => 'id.change_id = src.id',
        inner_join => 'topics t',
        on         => 't.id = id.issue_id',
        left_join  => 'topics ist',
        on         => 'ist.id = id.issue_status_id',
        left_join  => 'topics p',
        on         => 'p.id = id.project_id',

        # project_status
        union_all_select => [
            case (
                when => 'psd.new',
                then => qv('project_status'),
                else => qv('project_status_delta'),
            ),               # 0
            't.uuid',        # 1
            'p.uuid',        # 2
            'psd.status',    # 3
            'psd.rank',      # 4
            5, 6, 7, 8, 9, 10,
            'psd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'project_status_deltas psd',
        on         => 'psd.change_id = src.id',
        left_join  => 'project_status pst',
        on         => 'pst.id = psd.project_status_id',
        inner_join => 'topics t',
        on         => 't.id = pst.id',
        inner_join => 'topics p',
        on         => 'p.id = pst.project_id',

        # projects
        union_all_select => [
            case (
                when => 'pd.new',
                then => qv('project'),
                else => qv('project_delta'),
            ),                       # 0
            'p.uuid',                # 1
            'par.uuid',              # 2
            'pd.name',               # 3
            'pd.title',              # 4
            's.uuid',                # 5
            'h.uuid AS hub_uuid',    # 6
            7, 8, 9, 10,
            'pd.id AS delta_id',     # 11
        ],
        from       => 'src',
        inner_join => 'project_deltas pd',
        on         => 'pd.change_id = src.id',
        inner_join => 'topics p',
        on         => 'p.id = pd.project_id',
        left_join  => 'topics h',
        on         => 'h.id = pd.hub_id',
        left_join  => 'topics par',
        on         => 'par.id = pd.parent_id',
        left_join  => 'topics s',
        on         => 's.id = pd.project_status_id',

        # task_status
        union_all_select => [
            case (
                when => 'tsd.new',
                then => qv('task_status'),
                else => qv('task_status_delta'),
            ),               # 0
            't.uuid',        # 1
            'p.uuid',        # 2
            'tsd.status',    # 3
            'tsd.def',       # 4
            'tsd.rank',      # 5
            6, 7, 8, 9, 10,
            'tsd.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'task_status_deltas tsd',
        on         => 'tsd.change_id = src.id',
        left_join  => 'task_status ts',
        on         => 'ts.id = tsd.task_status_id',
        inner_join => 'topics t',
        on         => 't.id = ts.id',
        inner_join => 'topics p',
        on         => 'p.id = ts.project_id',

        # tasks
        union_all_select => [
            case (
                when => 'td.new',
                then => qv('task'),
                else => qv('task_delta'),
            ),             # 0
            't.uuid',      # 1
            'ts.uuid',     # 2
            'td.title',    # 3
            4, 5, 6, 7, 8, 9,
            10,
            'td.id AS delta_id',    # 11
        ],
        from       => 'src',
        inner_join => 'task_deltas td',
        on         => 'td.change_id = src.id',
        inner_join => 'topics t',
        on         => 't.id = td.task_id',
        left_join  => 'topics ts',
        on         => 'ts.id = td.task_status_id',

        # topics
        union_all_select => [
            qv('topic'),            # 0
            't.kind',               # 1
            2, 3, 4, 5, 6, 7, 8, 9, 10,
            't.delta_id',           # 11
        ],
        from       => 'src',
        inner_join => 'topics t',
        on         => 't.first_change_id = src.id',

        # Order everything correctly
        order_by => 'delta_id',
    );
}

my %args = (
    change => [
        qw/
          _
          uuid
          parent_uuid
          identity_uuid
          mtime
          mtimetz
          author
          email
          lang
          message
          ucount
          /
    ],
    change_delta => [
        qw/
          _
          action_topic_uuid_1
          action_topic_uuid_2
          action_format/
    ],
    entity => [
        qw/
          _
          topic_uuid
          name
          contact_uuid
          default_contact_method_uuid
          /
    ],
    entity_delta => [
        qw/
          _
          entity_uuid
          name
          contact_uuid
          default_contact_method_uuid
          /
    ],
    entity_contact_method => [
        qw/
          _
          topic_uuid
          method
          mvalue
          entity_uuid
          /
    ],
    entity_contact_method_delta => [
        qw/
          _
          entity_contact_method_uuid
          method
          mvalue
          /, undef
    ],
    hub => [
        qw/
          _
          topic_uuid
          name/
    ],
    hub_delta => [
        qw/
          _
          hub_uuid
          name/
    ],
    hub_repo => [
        qw/
          _
          topic_uuid
          hub_uuid
          location
          /
    ],
    hub_repo_delta => [
        qw/
          _
          hub_repo_uuid/, undef, qw/location/
    ],
    identity => [
        qw/
          _
          entity_uuid
          shortname
          /
    ],
    identity_delta => [
        qw/
          _
          identity_uuid
          shortname
          /
    ],
    issue => [
        qw/
          _
          topic_uuid
          issue_status_uuid
          /,
        undef,
        qw/
          title
          /
    ],
    issue_delta => [
        qw/
          _
          issue_uuid
          issue_status_uuid
          project_uuid
          title
          /
    ],
    issue_status => [
        qw/
          _
          topic_uuid
          project_uuid
          status
          def
          rank
          /
    ],
    issue_status_delta => [
        qw/
          issue_status_uuid/, undef,
        qw/
          _
          status
          def
          rank
          /
    ],
    project => [
        qw/
          _
          topic_uuid
          parent_uuid
          name
          title
          /
    ],
    project_delta => [
        qw/
          _
          project_uuid
          parent_uuid
          name
          title
          project_status_uuid
          hub_uuid
          /
    ],
    project_status => [
        qw/
          _
          topic_uuid
          project_uuid
          status
          rank
          /
    ],
    project_status_delta => [
        qw/
          _
          project_status_uuid/, undef,
        qw/
          status
          rank
          /
    ],
    task => [
        qw/
          _
          topic_uuid
          task_status_uuid
          title
          /
    ],
    task_delta => [
        qw/
          _
          task_uuid
          task_status_uuid
          title
          /
    ],
    task_status => [
        qw/
          _
          topic_uuid
          project_uuid
          status
          def
          rank
          /
    ],
    task_status_delta => [
        qw/
          _
          task_status_uuid/, undef,
        qw/
          status
          def
          rank
          /
    ],
    topic => [
        qw/
          _
          kind/
    ],
);

sub Bif::DB::st::changeset_ext {
    my $self = shift;

    my $i = 0;
    my $dcount;
    my @changeset;
    my $src;

    while ( my $row = $self->arrayref ) {
        my $kind = $row->[0];
        if ( $i == 0 and $kind ne 'change' ) {
            use Data::Dumper;
            warn "first row not a 'change' but $kind (for delta_id $row->[11]) "
              . Dumper($row);
        }

        $src = $args{$kind} || ( warn "unhandled kind: $kind" && next );

        # skip column 1 (kind) and column 2 (delta_id)
        my $delta =
          { map { defined $src->[$_] ? ( $src->[$_] => $row->[$_] ) : () }
              0 .. $#$src };

        if ( $i == 0 ) {
            $dcount = delete $delta->{ucount}
              || ( warn 'missing ucount'
                && next );
        }

        push( @changeset, $delta );

        $i++;
        last if $i == $dcount;
    }

    return if 0 == $i;
    warn "delta dcount mismatch: got: $i want:$dcount" unless $i == $dcount;

    return \@changeset;
}

1;

=head1 NAME

=for bif-doc #perl

Bif::DB::Plugin::Changes - read-write helper methods for a bif database

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Bif::DB;
    use Bif::DB::Plugin::Changes;

    my $db = Bif::DB->connect(...);

    # Now use dbh/st methods from Changes

=head1 DESCRIPTION

B<Bif::DB::Plugin::Changes> adds some changeset methods to L<Bif::DB>.

=head1 DBH METHODS

=over

=item xprepare_changeset_ext() -> $sth

=back

=head1 ST METHODS

=over

=item changeset_ext() -> ArrayRef

=back

=head1 SEE ALSO

L<Bif::DB>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

