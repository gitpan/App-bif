package Bif::DB::RW;
use strict;
use warnings;
use Bif::DB;
use DBIx::ThinSQL qw//;
use DBIx::ThinSQL::SQLite ':all';
use Log::Any '$log';

our $VERSION = '0.1.0_6';
our @ISA     = ('Bif::DB');

create_methods(qw/nextval currval/);

sub _connected {
    my $dbh   = shift;
    my $debug = shift;

    $dbh->sqlite_trace( sub { $log->debug(@_) } ) if $debug;

    $dbh->do('PRAGMA foreign_keys = ON;');
    $dbh->do('PRAGMA temp_store = MEMORY;');
    $dbh->do('PRAGMA recursive_triggers = ON;');
    $dbh->do('PRAGMA synchronous = NORMAL;');
    $dbh->do('PRAGMA synchronous = OFF;') if $main::BIF_DB_NOSYNC;

    # TODO remove this before the first production release.
    $dbh->do('PRAGMA reverse_unordered_selects = ON;');

    create_functions( $dbh,
        qw/debug create_sequence nextval currval sha1_hex agg_sha1_hex/ );
    return;
}

sub connect {
    my $class = shift;
    my $dsn   = shift;
    my ( $user, $password, $attrs, $debug ) = @_;

    $attrs ||= {
        RaiseError                 => 1,
        PrintError                 => 0,
        ShowErrorStatement         => 1,
        sqlite_see_if_its_a_number => 1,
        sqlite_unicode             => 1,
        Callbacks                  => {
            connected => sub { _connected( shift, $debug ) }
        },
    };

    return $class->SUPER::connect( $dsn, $user, $password, $attrs );
}

package Bif::DB::RW::db;
our @ISA = ('Bif::DB::db');

use DBIx::ThinSQL qw/qv/;

sub deploy {
    my $db = shift;

    require DBIx::ThinSQL::Deploy;

    $db->txn(
        sub {
            if ( defined &static::find ) {
                my $src =
                  'auto/share/dist/App-bif/' . $db->{Driver}->{Name} . '.sql';

                my $sql = static::find($src)
                  or die 'unsupported database type: ' . $db->{Driver}->{Name};

                return $db->deploy_sql($sql);
            }
            else {
                require File::ShareDir;
                require Path::Tiny;

                my $share_dir = $main::BIF_SHARE_DIR
                  || File::ShareDir::dist_dir('App-bif');

                my $deploy_dir =
                  Path::Tiny::path( $share_dir, $db->{Driver}->{Name} );

                if ( !-d $deploy_dir ) {
                    die 'unsupported database type: ' . $db->{Driver}->{Name};
                }

                DBIx::ThinSQL::SQLite::create_sqlite_sequence($db);
                return $db->deploy_dir($deploy_dir);
            }
        }
    );
}

sub update_repo {
    my $dbw = shift;
    my $ref = shift;

    my $repo = $dbw->get_topic( $dbw->get_local_repo_id );
    my $uid  = $dbw->nextval('updates');

    $dbw->xdo(
        insert_into => 'updates',
        values      => {
            id        => $uid,
            parent_id => $repo->{first_update_id},
            author    => $ref->{author},
            email     => $ref->{email},
            message   => $ref->{message},
        },
    );

    $dbw->xdo(
        insert_into => [
            'repo_updates',
            qw/repo_id update_id related_update_uuid project_id/
        ],
        select =>
          [ qv( $repo->{id} ), qv($uid), 'ru.uuid', qv( $ref->{project_id} ), ],
        from      => '(select 1)',
        left_join => 'topics ru',
        on        => {
            'ru.id' => $ref->{related_update_id},
        },
    );

    $dbw->xdo(
        insert_into => 'func_merge_updates',
        values      => { merge => 1 },
    );

    return;
}

package Bif::DB::RW::st;
our @ISA = ('Bif::DB::st');

1;
