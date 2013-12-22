package Bif::DB;
use strict;
use warnings;
use DBIx::ThinSQL ();
use Carp          ();

our $VERSION = '0.1.0';
our @ISA     = ('DBIx::ThinSQL');

sub connect {
    my $class    = shift;
    my $dsn      = shift;
    my $username = shift;
    my $password = shift;
    my $options  = shift || {
        RaiseError                 => 1,
        PrintError                 => 0,
        ShowErrorStatement         => 1,
        sqlite_see_if_its_a_number => 1,
        sqlite_unicode             => 1,
        Callbacks                  => {
            connected => sub {
                my $dbh = shift;
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
            },
          }

    };

    return $class->SUPER::connect( $dsn, $username, $password, $options );
}

package Bif::DB::db;
use DBIx::ThinSQL qw/ qv bv /;

our @ISA = ('DBIx::ThinSQL::db');

sub path2project_id {
    my $db   = shift;
    my $path = shift;

    my ($id) = $db->xarray(
        select => 'projects.id',
        from   => 'projects',
        where  => [ 'projects.path = ', qv($path) ],
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

sub get_project {
    my $self = shift;
    my $token = shift || return;

    my $data = $self->xhash(
        select => [
            'topics.id',     'topics.kind',
            'topics.uuid',   'projects.parent_id',
            'projects.path', 'topics.first_update_id'
        ],
        from       => 'projects',
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        where      => { 'projects.path' => $token },
    );

    return $data;
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

sub hub_info {
    my $self = shift;
    my $alias = shift || return;

    my $data = $self->xhash(
        select => [ 'hubs.id', 'hubs.alias', 'hubs.location', ],
        from   => 'hubs',
        where => { 'hubs.alias' => $alias },
    );

    return $data;
}

package Bif::DB::st;
our @ISA = ('DBIx::ThinSQL::st');

1;
