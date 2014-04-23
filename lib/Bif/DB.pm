package Bif::DB;
use strict;
use warnings;
use DBIx::ThinSQL ();
use Carp          ();
use Log::Any '$log';

our $VERSION = '0.1.0_13';
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

sub get_topic {
    my $self = shift;
    my $token = shift || return;

    if ( $token =~ m/^\d+$/ ) {
        my $data = $self->xhash(
            select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'topics.first_update_id',
                qv(undef)->as('project_issue_id'),
                qv(undef)->as('project_id'),
            ],
            from  => 'topics',
            where => [
                'topics.id = ',         bv($token),
                ' AND topics.kind != ', qv('issue')
            ],
            union_all_select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'topics.first_update_id',
                'project_issues.id AS project_issue_id',
                'project_issues.project_id',
            ],
            from       => 'project_issues',
            inner_join => 'topics',
            on         => 'topics.id = project_issues.issue_id',
            where      => { 'project_issues.id' => $token },
        );

        return $data;
    }
    return;
}

sub uuid2id {
    my $self = shift;
    my $uuid = shift || return;

    my ($id) = $self->xarray(
        select => 't.id',
        from   => 'topics t',
        where  => { 't.uuid' => $uuid },
    );
    return $id;
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

sub get_local_repo_id {
    my $self = shift;

    my $repo = $self->xarray(
        select => ['repos.id'],
        from   => 'repos',
        where  => { 'repos.local' => 1 },
    );

    if ( !$repo ) {
        warn "get_local_repo_id: no local repo!";
        return;
    }
    return $repo->[0];
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
            inner_join => 'repos r',
            on         => {
                'r.id'    => \'p.repo_id',
                'r.alias' => $alias,
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

sub get_repo_locations {
    my $self = shift;
    my $alias = shift || return;

    return $self->xhashes(
        select => [
            'r.id AS id',
            't.uuid AS uuid',
            'r.alias AS alias',
            'rl.location AS location',
            'r.default_location_id = rl.id AS is_default'
        ],
        from       => 'repos r',
        inner_join => 'topics t',
        on         => 't.id = r.id',
        inner_join => 'repo_locations rl',
        on         => 'rl.repo_id = r.id',
        where      => {
            'r.alias' => $alias,
        },
        union_all_select => [
            'r.id', 't.uuid', 'r.alias',
            'rl.location', 'r.default_location_id = rl.id AS is_default'
        ],
        from       => 'repo_locations rl2',
        inner_join => 'repos r',
        on         => 'r.id = rl2.repo_id',
        inner_join => 'topics t',
        on         => 't.id = r.id',
        inner_join => 'repo_locations rl',
        on         => 'rl.repo_id = r.id',
        where      => {
            'rl2.location' => $alias,
        },
        order_by => 'is_default ASC',
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

0.1.0_13 (2014-04-23)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Bif::DB;

    # Bif::DB inherits from DBIx::ThinSQL, which inherits from DBI.
    my $db = Bif::DB->connect( $dsn );

    # Read only operations on a bif database:
    my $id = $db->uuid2id( $uuid );

=head1 DESCRIPTION

B<Bif::DB> is a L<DBI> derivative that provides various read-only
methods for retrieving information from a L<bif> repository. For a
read-write equivalent see L<Bif::DBW>. The read-only and read-write
parts are separated for performance reasons.

=head1 METHODS

=over

=item uuid2id( $UUID ) -> Int | Undef

Returns the integer ID matching a topic C<$UUID>, or C<undef> if no
match is found.

=item get_topic( $ID ) -> HashRef

Looks up the topic identified by C<$ID> and returns undef or a hash
reference containg the following keys:

=over

=item * id - the topic ID

=item * first_update_id - the update_id that created the topic

=item * kind - the type of the topic

=item * uuid - the universally unique identifier of the topic

=back

If C<$ID> has a length of 40 characters the search will be performed on
the basis that it is a UUID.

If the found topic is an issue then the following keys will also
contain valid values:

=over

=item * project_issue_id - the project-specific topic ID

=item * project_id - the project ID matching the project_issue_id

=back

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


=item get_local_repo_id -> Int

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

=item get_repo_locations( $alias ) -> @HashRef

Returns a list of HASH references containing information about the hub
identified by C<$alias>, each with the following keys:

=over

=item * id - the topic ID for the hub

=item * alias - the alias for the hub

=item * location - the location of the hub

=item * is_default - true if it is the default location

=back

Returns C<undef> if C<$alias> is not found.

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

