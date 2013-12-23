use strict;
use warnings;
use lib 't/lib';
use Path::Tiny qw/cwd/;
use App::bif::Util;
use Test::More;
use Test::Bif;

plan skip_all => 'developer-only schema extraction'
  unless -d '.git';

run_in_tempdir {
    my $db    = bif(qw/ init /);
    my $items = $db->selectall_arrayref(
        "SELECT sql FROM sqlite_master
        WHERE sql IS NOT NULL
        ORDER BY
            tbl_name,
            CASE
                type
            WHEN
                'table'
            THEN
                1
            WHEN
                'index'
            THEN
                2
            ELSE
                3
            END,
            name"
    );
    my $sql = join( "\n\n", map { $_->[0] } @$items );

    my $outfile = $main::BIF_SHARE_DIR->child('SQLite.sql');

    # Try and remind ourselves that we shouldn't be editing this file
    # from the shell
    chmod 0644, $outfile;
    ok $outfile->spew($sql), 'saved to ' . $outfile;
    chmod 0444, $outfile;
};

done_testing();

