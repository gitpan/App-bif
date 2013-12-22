package Bif::DB::RW;
use strict;
use warnings;
use Bif::DB;
use DBIx::ThinSQL qw//;
use DBIx::ThinSQL::SQLite ':all';

our $VERSION = '0.1.0';
our @ISA     = ('Bif::DB');

create_methods(qw/nextval currval/);

sub _connected {
    my $dbh = shift;
    $dbh->do('PRAGMA foreign_keys = ON;');
    $dbh->do('PRAGMA temp_store = MEMORY;');
    $dbh->do('PRAGMA recursive_triggers = ON;');
    $dbh->do('PRAGMA synchronous = NORMAL;');
    $dbh->do('PRAGMA synchronous = OFF;') if $Test::Bif::SHARE_DIR;

    # TODO remove this before the first production release.
    $dbh->do('PRAGMA reverse_unordered_selects = ON;');

    create_functions( $dbh,
        qw/debug create_sequence nextval currval sha1_hex agg_sha1_hex/ );
    return;
}

sub connect {
    my $class = shift;
    my $dsn   = shift;

    return $class->SUPER::connect(
        $dsn, '', '',
        {
            RaiseError                 => 1,
            PrintError                 => 0,
            ShowErrorStatement         => 1,
            sqlite_see_if_its_a_number => 1,
            sqlite_unicode             => 1,
            Callbacks                  => { connected => \&_connected },
        },

    );
}

package Bif::DB::RW::db;
our @ISA = ('Bif::DB::db');

package Bif::DB::RW::st;
our @ISA = ('Bif::DB::st');

1;
