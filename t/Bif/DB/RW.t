use strict;
use warnings;
use lib 't/lib';
use Bif::DB::RW;
use Test::Bif;
use Test::More;

run_in_tempdir {
    my $db = Bif::DB::RW->connect('dbi:SQLite:dbname=x.sqlite3');

    isa_ok $db, 'Bif::DB::RW::db';

    my ( $old, $new ) = $db->deploy;
    is $old, 0, 'started empty';
    ok $new, 'deployed statements: ' . $new;
};

done_testing();
