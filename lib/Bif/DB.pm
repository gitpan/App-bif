package Bif::DB;
use strict;
use warnings;
use DBIx::ThinSQL ();
use Carp          ();
use Log::Any '$log';

our $VERSION = '0.1.0_19';
our @ISA     = ('DBIx::ThinSQL');

sub _connected {
    my $dbh   = shift;
    my $debug = shift;

    $dbh->sqlite_trace( sub { $log->debug(@_) } ) if $debug;

    # $dbh->trace('1|SQL',\*STDOUT) if $debug;

    $dbh->do('PRAGMA foreign_keys = ON;');
    $dbh->do('PRAGMA temp_store = MEMORY;');

    # TODO remove these before the first production release.
    {
        $dbh->do('PRAGMA reverse_unordered_selects = ON;');

        use DBD::SQLite;
        $dbh->sqlite_set_authorizer(
            sub {
                return
                     $_[0] == DBD::SQLite::SELECT
                  || $_[0] == DBD::SQLite::READ
                  || $_[0] == DBD::SQLite::FUNCTION
                  ? DBD::SQLite::OK
                  : DBD::SQLite::DENY;
            }
        );
    }
    return;
}

sub connect {
    my $class = shift;
    my ( $dsn, $username, $password, $attrs, $debug ) = @_;

    $attrs ||= {
        RaiseError                 => 1,
        PrintError                 => 0,
        ShowErrorStatement         => 1,
        sqlite_see_if_its_a_number => 1,
        sqlite_unicode             => 1,
        Callbacks                  => {
            connected => sub { _connected( shift, $debug ) },
        },
    };

    return $class->SUPER::connect( $dsn, $username, $password, $attrs, );
}

package Bif::DB::db;
use DBIx::ThinSQL qw/ qv bv /;

our @ISA = ('DBIx::ThinSQL::db');

sub uuid2id {
    my $self = shift;
    my $uuid = shift || return;

    if ( length($uuid) == 40 ) {
        return $self->xarrays(
            select => 't.id',
            from   => 'topics t',
            where  => { 't.uuid' => $uuid },
        );
    }

    return $self->xarrays(
        select => 't.id',
        from   => 'topics t',
        where  => [ 't.uuid LIKE ', qv( $uuid . '%' ) ],
    );
}

sub get_update {
    my $self = shift;
    my $token = shift || return;

    if ( $token =~ m/^(\d+)\.(\d+)$/ ) {
        my $id        = $1;
        my $update_id = $2;
        my $data      = $self->xhash(
            select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'updates.id AS update_id',
                qv(undef)->as('project_issue_id'),
                qv(undef)->as('project_id'),
            ],
            from       => 'topics',
            inner_join => 'updates',
            on         => { 'updates.id' => $update_id },
            where =>
              [ 'topics.id = ', bv($id), ' AND topics.kind != ', qv('issue') ],
            union_all_select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'updates.id AS update_id',
                'project_issues.id AS project_issue_id',
                'project_issues.project_id',
            ],
            from       => 'project_issues',
            inner_join => 'topics',
            on         => 'topics.id = project_issues.issue_id',
            inner_join => 'updates',
            on         => { 'updates.id' => $update_id },
            where      => { 'project_issues.id' => $id },
        );
        return $data;
    }

    return;
}

sub get_local_hub_id {
    my $self = shift;

    my $hub = $self->xarray(
        select => ['hubs.id'],
        from   => 'hubs',
        where  => { 'hubs.local' => 1 },
    );

    if ( !$hub ) {
        warn "get_local_hub_id: no local repo!";
        return;
    }
    return $hub->[0];
}

sub get_projects {
    my $self  = shift;
    my $path  = shift || return;
    my $alias = shift;             # hub alias

    if ($alias) {
        return $self->xhashes(
            select => [
                't.id',   't.kind',
                't.uuid', 'p.parent_id',
                'p.path', 't.first_update_id',
                'p.local',
            ],
            from       => 'projects p',
            inner_join => 'hubs h',
            on         => {
                'h.id'    => \'p.hub_id',
                'h.alias' => $alias,
            },
            inner_join => 'topics t',
            on         => 't.id = p.id',
            where      => { 'p.path' => $path },
        );
    }

    return $self->xhashes(
        select => [
            't.id',   't.kind',            't.uuid', 'p.parent_id',
            'p.path', 't.first_update_id', 'p.local',
        ],
        from       => 'projects p',
        inner_join => 'topics t',
        on         => 't.id = p.id',
        where      => {
            'p.path'  => $path,
            'p.local' => 1,
        },
    );
}

sub status_ids {
    my $self       = shift;
    my $project_id = shift;
    my $kind       = shift;

    return ( [], [] ) unless $project_id and $kind and @_;

    my @ids;
    my %invalid = map { defined $_ ? ( $_ => 1 ) : () } @_;

    my @known = $self->xarrays(
        select => 'id, status',
        from   => $kind . '_status',
        where  => { project_id => $project_id },
    );

    foreach my $known (@known) {
        push( @ids, $known->[0] )
          if delete $invalid{ $known->[1] };
    }

    # sorted keys so we can test
    return \@ids, [ sort keys %invalid ];
}

sub get_hub_locations {
    my $self = shift;
    my $alias = shift || return;

    return $self->xhashes(

        # TODO get rid of this select once everything uses ctx->uuid2id
        select => [
            'h.id AS id',
            't.uuid AS uuid',
            'h.alias AS alias',
            'hl.location AS location',
            'h.default_location_id = hl.id AS is_default'
        ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        inner_join => 'hub_locations hl',
        on         => 'hl.hub_id = h.id',
        where      => {
            'h.alias' => $alias,
        },
        union_all_select => [
            'h.id AS id',
            't.uuid AS uuid',
            'h.alias AS alias',
            'hl.location AS location',
            'h.default_location_id = hl.id AS is_default'
        ],
        from       => 'hubs h',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        inner_join => 'hub_locations hl',
        on         => 'hl.hub_id = h.id',
        where      => {
            'h.id' => $alias,
        },
        union_all_select => [
            'h.id', 't.uuid', 'h.alias',
            'hl.location', 'h.default_location_id = hl.id AS is_default'
        ],
        from       => 'hub_locations hl2',
        inner_join => 'hubs h',
        on         => 'h.id = hl2.hub_id',
        inner_join => 'topics t',
        on         => 't.id = h.id',
        inner_join => 'hub_locations hl',
        on         => 'hl.hub_id = h.id',
        where      => {
            'hl2.location' => $alias,
        },
        order_by => [qw/alias location/],
    );
}

sub get_max_update_id {
    my $self = shift;
    my ($uid) = $self->xarray(
        select => ['MAX(u.id)'],
        from   => 'updates u',
    );

    return $uid;

}

package Bif::DB::st;
our @ISA = ('DBIx::ThinSQL::st');

1;

=head1 NAME

Bif::DB - helper methods for a read-only bif database

=head1 VERSION

0.1.0_19 (2014-05-08)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Bif::DB;

    # Bif::DB inherits from DBIx::ThinSQL, which inherits from DBI.
    my $db = Bif::DB->connect( $dsn );

    # Read only operations on a bif database:
    my @ids = $db->uuid2id( $uuid );

=head1 DESCRIPTION

B<Bif::DB> is a L<DBI> derivative that provides various read-only
methods for retrieving information from a L<bif> repository. For a
read-write equivalent see L<Bif::DBW>. The read-only and read-write
parts are separated for performance reasons.

=head1 METHODS

=over

=item uuid2id( $UUID ) -> List[Int]

Returns the (possibly multiple) integer ID(s) matching a topic
C<$UUID>.

=item get_update( "$ID.$UPDATE_ID" ) -> HashRef

Looks up the update identified by C<$ID.$UPDATE_ID> and returns undef
or a hash reference containg the following keys:

=over

=item * id - the topic ID

=item * update_id - the ID of the update

=item * kind - the type of the topic

=item * uuid - the universally unique identifier of the topic

=back

If the update relates to an issue then the following keys will also
contain valid values:

=over

=item * project_issue_id - the project-specific topic ID

=item * project_id - the project ID matching the project_issue_id

=back


=item get_local_hub_id -> Int

Returns the ID for the local repository topic.

=item get_projects( $PATH, [$ALIAS] ) -> [HashRef, ...]

Looks up the project(s) identified by C<$PATH> (and optionally a hub
C<$ALIAS>) returns undef, or a list of hash references containg the
following keys:

=over

=item * id - the topic ID

=item * first_update_id - the update_id that created the topic

=item * kind - the type of the topic

=item * uuid - the universally unique identifier of the topic

=item * path - the path of the project

=item * parent_id - the parent ID of the project

=item * local - true if the project is locally synchronized

=back

=item status_ids( $project_id, $kind, @status ) -> \@ids, \@invalid

Takes a project ID, a thread type (task, issue, etc) and a list of
status names and returns an arrayref of matching IDs, and an arrayref
of invalid names. This method will silently ignore any @status which
are undefined.

=item get_hub_locations( $alias ) -> @HashRef

Returns a list of HASH references containing information about the hub
identified by C<$alias>, each with the following keys:

=over

=item * id - the topic ID for the hub

=item * alias - the alias for the hub

=item * location - the location of the hub

=item * is_default - true if it is the default location

=back

Returns C<undef> if C<$alias> (an alias, an ID, or a location) is not
found.

=item get_max_update_id

Returns the maximum update ID in the database.

=back

=head1 SEE ALSO

L<Bif::DBW>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

