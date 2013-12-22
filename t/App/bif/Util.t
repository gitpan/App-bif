use strict;
use warnings;
use lib 't/lib';
use Log::Any::Test '$log';
use App::bif::Util;
use File::chdir;
use Log::Any qw/$log/;
use Path::Tiny qw/path tempfile cwd/;
use Term::ANSIColor qw/color/;
use Test::Bif;    # really only to set $Test::Bif::SHARE_DIR
use Test::More;
use Test::Fatal qw/exception/;

open STDOUT, '>', \my $out;

subtest 'Bif::OK', sub {

    my $ok = Bif::OK->new('Token');
    isa_ok $ok, 'Bif::OK::Token';
    is "$ok", 'Bif::OK::Token', 'stringify no message';

    $ok = Bif::OK->new( 'Token2', 'text' );
    isa_ok $ok, 'Bif::OK::Token2';
    is "$ok", 'text', 'stringify with message';

    my $ref = ['text'];
    $ok = Bif::OK->new( 'Token3', $ref );
    isa_ok $ok, 'Bif::OK::Token3';
};

subtest 'Bif::Error', sub {

    my $ok = Bif::Error->new('Token');
    isa_ok $ok, 'Bif::Error::Token';
    is "$ok", 'Bif::Error::Token', 'stringify no message';

    $ok = Bif::Error->new( 'Token2', 'text' );
    isa_ok $ok, 'Bif::Error::Token2';
    is "$ok", 'text', 'stringify with message';

};

subtest 'bif_init', sub {

    like exception { bif_init }, qr/usage: bif_init/, 'bif_init no arg';
    isa_ok bif_init( {} ), 'HASH';

    # When testing anything related to debug it is important to specify
    # 'no_pager', otherwise you'll spend ages looking for an issue in
    # IO::Pager. The Test::Bif functions normally take care of this for
    # us.
    bif_init( { debug => 1, no_pager => 1 } );
    $log->contains_ok( qr/bif_init:/, 'debugging on' );

};

# color - not tested

subtest 'bif_err', sub {
    is exception { bif_err( 'Token', 'text' ) }, "fatal: text\n", 'fatal text';
    is exception { bif_err( 'Token', 'text %d %s', 1, 'a string' ) },
      "fatal: text 1 a string\n", 'fatal text';
    isa_ok exception { bif_err( 'Token', 'text' ) }, 'Bif::Error::Token';
};

subtest 'bif_ok', sub {
    isa_ok bif_ok('Token'), 'Bif::OK::Token';
    is bif_ok('Token2'), 'Bif::OK::Token2', 'stringification';
    isa_ok bif_ok( 'Token3', 'text' ), 'Bif::OK::Token3', 'ok with text';
    is bif_ok( 'Token4', 'text' ), 'text', 'stringification';
};

# start_pager - not tested

# end_pager - not tested

subtest 'bif_repo', sub {
    run_in_tempdir {
        isa_ok exception { bif_repo }, 'Bif::Error::RepoNotFound';

        my $repo = cwd->child('.bif');
        mkdir $repo;
        is bif_repo, $repo, 'bif_repo .bif';

        mkdir 'subdir';
        local $CWD = 'subdir';
        is bif_repo, $repo, 'bif_repo ../.bif';

        my $repo2 = cwd->child('.bif');
        mkdir $repo2;
        is bif_repo, $repo2, 'found current with parent repo existing';
    };
};

subtest 'bif_conf', sub {
    run_in_tempdir {

        # bif_user_conf - should exist regardless
        isa_ok bif_user_conf, 'HASH';

        # bif_conf
        isa_ok exception { bif_conf }, 'Bif::Error::RepoNotFound';

        mkdir '.bif';

        isa_ok exception { bif_conf }, 'Bif::Error::ConfigNotFound';
        open( my $fh, '>', path( '.bif', 'config' ) ) or die "open: $!";
        print $fh "\n";
        close $fh;
        isa_ok bif_conf, 'HASH';

    };
};

subtest 'bif_db', sub {
    run_in_tempdir {
        isa_ok exception { bif_db }, 'Bif::Error::RepoNotFound';
        isa_ok bif_db('.'), 'Bif::DB::db';

        # check again that there is no 'current' repo
        isa_ok exception { bif_db }, 'Bif::Error::RepoNotFound', 'again';

        mkdir '.bif';
        my $db = bif_db;
        isa_ok $db, 'Bif::DB::db';

        like exception { $db->do('select sha(1)') }, qr/no such function/,
          'read-only';
    };
};

subtest 'bif_dbw', sub {
    run_in_tempdir {
        isa_ok exception { bif_dbw }, 'Bif::Error::RepoNotFound';
        isa_ok bif_dbw('.'), 'Bif::DB::RW::db';

        # check again that there is no 'current' repo
        isa_ok exception { bif_dbw }, 'Bif::Error::RepoNotFound', 'again';

        mkdir '.bif';

        my $db = bif_dbw;
        isa_ok $db, 'Bif::DB::RW::db';
        my $sha1 = Digest::SHA::sha1_hex(1);
        my ($sha) = $db->selectrow_array('select sha1_hex(1)');
        is $sha, $sha1, 'read-write';
    };
};

subtest 'render_table', sub {

    is render_table( 'l r', undef, [ [ 'apple', 1.3 ] ] ),
      <<"END", 'render_table ok';
apple 1.3
END

    is render_table( 'l r', [ 'Item', 'Cost' ], [ [ 'apple', 1.3 ] ] ),
      <<"END", 'render_table ok';
Item  Cost
----------
apple  1.3
END

    is render_table( 'l r', [ 'Item', 'Cost' ], [ [ 'apple', 1.3 ] ], 1 ),
      <<"END", 'render_table ok';
 Item  Cost
 ----------
 apple  1.3
END

};

subtest 'prompt_edit', sub {

    isa_ok exception { prompt_edit }, 'Bif::Error::EmptyContent';

    is prompt_edit( val => 'Not empty' ), "Not empty\n",
      'prompt_edit not empty';
};

done_testing();
