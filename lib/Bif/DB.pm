package Bif::DB;
use strict;
use warnings;
use DBIx::ThinSQL ();
use Carp          ();
use Log::Any '$log';

our $VERSION = '0.1.0_6';
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

sub path2project_id {
    my $db      = shift;
    my $path    = shift;
    my $repo_id = shift || $db->get_local_repo_id;

    my ($id) = $db->xarray(
        select     => 'p.id',
        from       => 'projects p',
        inner_join => 'repo_projects rp',
        on         => {
            'rp.project_id' => \'p.id',
            'rp.repo_id'    => $repo_id,
        },
        where => [ 'p.path = ', qv($path) ],
    );

    return $id;
}

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

sub get_project {
    my $self  = shift;
    my $token = shift || return;
    my $alias = shift;             # hub alias

    if ($alias) {
        return $self->xhash(
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
            where      => { 'p.path' => $token },
        );
    }

    my @tries = $self->xhash(
        select => [
            't.id',   't.kind',            't.uuid', 'p.parent_id',
            'p.path', 't.first_update_id', 'p.local',
        ],
        from       => 'projects p',
        inner_join => 'topics t',
        on         => 't.id = p.id',
        where      => { 'p.path' => $token, 'p.local' => 1, },
    );

    return -scalar @tries if @tries > 1;
    return $tries[0];
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
