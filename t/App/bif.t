use strict;
use warnings;
use lib 't/lib';
use Log::Any::Test;
use App::bif;
use File::chdir;
use Log::Any qw/$log/;
use Path::Tiny qw/path cwd/;
use Test::Bif;
use Test::More;
use Test::Fatal qw/exception/;

#open STDOUT, '>', \my $out;

my $newopts = {
    no_pager => 1,
    no_color => 1,
};

subtest 'Bif::OK', sub {

    my $ok = Bif::OK->new( {}, 'Token' );
    isa_ok $ok, 'Bif::OK::Token';
    is "$ok", 'Bif::OK::Token', 'stringify no message';

    $ok = Bif::OK->new( {}, 'Token2', 'text' );
    isa_ok $ok, 'Bif::OK::Token2';
    is "$ok", 'text', 'stringify with message';

    my $ref = { one => 1 };
    $ok = Bif::OK->new( $ref, 'Token3' );
    isa_ok $ok, 'Bif::OK::Token3';
    is $ok->{one}, 1, 'data match';
};

subtest 'Bif::Error', sub {

    my $err = Bif::Error->new( {}, 'Error' );
    isa_ok $err, 'Bif::Error::Error';
    like "$err", qr/Bif::Error::Error/, 'stringify exception no message';

    $err = Bif::Error->new( { one => 1 }, 'Error2', 'text' );
    isa_ok $err, 'Bif::Error::Error2';
    like "$err", qr/text/, 'stringify exception with message';
    is $err->{one}, 1, 'data match';

};

run_in_tempdir {

    subtest 'new', sub {
        like exception { App::bif->new },
          qr/opts required/, 'App::bif->new usage';

        my $ctx = App::bif->new( opts => $newopts );
        isa_ok $ctx, 'App::bif';

        # When testing anything related to debug it is important to specify
        # 'no_pager', otherwise you'll spend ages looking for an issue in
        # IO::Pager. The Test::Bif functions normally take care of this for
        # us.
        App::bif->new( opts => { debug => 1, no_pager => 1 } );
        $log->contains_ok( qr/bif:/, 'debugging on' );
    };

    my $ctx = App::bif->new( opts => $newopts );

    # color - not tested

    subtest 'err', sub {
        my $e = exception { $ctx->err( 'Token', 'text' ) };
        isa_ok $e, "Bif::Error::Token";
        like $e, qr/error:.*text/, 'error text';
        like exception {
            $ctx->err( 'Token', 'text %d %s', 1, 'a string' );
        }, qr/error:.*text 1 a string/, 'error text interpolation';
    };

    subtest 'ok', sub {
        isa_ok $ctx->ok('Token'), 'Bif::OK::Token';
        is $ctx->ok('Token2'), 'Bif::OK::Token2', 'stringification';
        isa_ok $ctx->ok( 'Token3', 'text' ), 'Bif::OK::Token3', 'ok with text';
        is $ctx->ok( 'Token4', 'text' ), 'text', 'stringification';
    };

    #$ctx->start_pager - not tested

    # end_pager - not tested

    subtest 'not found exceptions' => sub {
        isa_ok exception { $ctx->user_repo }, 'Bif::Error::UserRepoNotFound';
        isa_ok exception { $ctx->user_db },   'Bif::Error::UserRepoNotFound';
        isa_ok exception { $ctx->user_dbw },  'Bif::Error::UserRepoNotFound';
        isa_ok exception { $ctx->repo },      'Bif::Error::UserRepoNotFound';
        isa_ok exception { $ctx->db },        'Bif::Error::UserRepoNotFound';
        isa_ok exception { $ctx->dbw },       'Bif::Error::UserRepoNotFound';
    };

    bif(qw/init/);
    $ctx = App::bif->new( opts => $newopts );

    subtest 'repo', sub {
        isa_ok $ctx->repo, 'Path::Tiny';

        mkdir 'subdir';
        local $CWD = 'subdir';
        my $ctx2 = App::bif->new( opts => $newopts );
        is $ctx2->repo, $ctx->repo, 'subdir';

        bif('init');
        my $ctx3 = App::bif->new( opts => $newopts );
        is $ctx3->repo, $ctx->repo->parent->child(qw/subdir .bif/),
          'subdir repo';
    };

    subtest 'config', sub {
        like $ctx->config->{'user.alias'}->{ls}, qr/list/, 'config alias';
    };

    subtest 'db', sub {
        my $db = $ctx->db;
        isa_ok $db, 'Bif::DB::db';

        like exception { $db->do('select sha(1)') }, qr/no such function/,
          'read-only';
    };

    subtest '$ctx->dbw', sub {
        my $dbw = $ctx->dbw;
        isa_ok $dbw, 'Bif::DBW::db';
        my $sha1 = Digest::SHA::sha1_hex(1);
        my ($sha) = $dbw->selectrow_array('select sha1_hex(1)');
        is $sha, $sha1, 'read-write';
    };

    subtest '$ctx->uuid2id', sub {
        is 1, $ctx->uuid2id(1), 'uuid2id with no uuid';
        $ctx->opts->{uuid}++;
        isa_ok exception { $ctx->uuid2id('X') }, 'Bif::Error::UuidNotFound';
    };

    subtest 'render_table', sub {

        is $ctx->render_table( 'l r', undef, [ [ 'apple', 1.3 ] ] ),
          <<"END", 'render_table ok';
apple 1.3
END

        is $ctx->render_table( 'l r', [ 'Item', 'Cost' ],
            [ [ 'apple', 1.3 ] ] ),
          <<"END", 'render_table ok';
Item  Cost
apple  1.3
END

        is $ctx->render_table(
            'l r',
            [ 'Item', 'Cost' ],
            [ [ 'apple', 1.3 ] ], 1
          ),
          <<"END", 'render_table ok';
 Item  Cost
 apple  1.3
END

    };

    subtest 'prompt_edit', sub {

        isa_ok exception { $ctx->prompt_edit }, 'Bif::Error::EmptyContent';

        is $ctx->prompt_edit( val => 'Not empty' ), "Not empty\n",
          'prompt_edit not empty';
    };

    subtest 'get_change', sub {
        my $dbw = $ctx->dbw;
        my $uid;
        $dbw->txn(
            sub {
                isa_ok exception { $ctx->get_change('not a cID') },
                  'Bif::Error::ChangeNotFound';

                isa_ok exception { $ctx->get_change(1000000) },
                  'Bif::Error::ChangeNotFound';

                isa_ok exception { $ctx->get_change('c1000000') },
                  'Bif::Error::ChangeNotFound';

                $uid = $ctx->new_change( action => 'junk', );
            }
        );

        # The ->db handle doesn't see updates within the txn above
        my $res = $ctx->get_change( 'c' . $uid );
        is $res->{id}, $uid, 'uid found';
    };

    subtest 'get_topic', sub {
        my ( $uid, $project, $ps, $ts, $is, $task, $issue );
        $project = bif(qw/new project x title -m m1/);
        $task    = bif(qw/new task x title -m m2/);
        $issue   = bif(qw/new issue x title -m m3/);

        my $ref;

        isa_ok exception { $ctx->get_topic(-1) }, 'Bif::Error::TopicNotFound';

        is_deeply $ref = $ctx->get_topic( $project->{id} ), {
            id              => $project->{id},
            first_change_id => $project->{change_id},
            kind            => 'project',
            uuid             => $ref->{uuid},    # hard to know this in advance
            project_issue_id => undef,
            project_id       => undef,
          },
          'get_topic project ID';

        my $db  = $ctx->db;
        my @ids = $db->uuid2id( $ref->{uuid} );

        is $ids[0][0], $project->{id}, 'uuid2id() id';
        is $ids[0][1], $ref->{uuid},   'uuid2id() uuid';

        @ids = $db->uuid2id( substr( $ref->{uuid}, 0, 13 ) );

        is $ids[0][0], $project->{id}, 'uuid2id() partial id';
        is $ids[0][1], $ref->{uuid},   'uuid2id() partial uuid';

        is_deeply $ref = $ctx->get_topic( $task->{id} ), {
            id              => $task->{id},
            first_change_id => $task->{change_id},
            kind            => 'task',
            uuid            => $ref->{uuid},      # hard to know this in advance
            project_issue_id => undef,
            project_id       => undef,
          },
          'get_topic task ID';

        is_deeply $ref = $ctx->get_topic( $issue->{id} ), {
            id              => $issue->{topic_id},
            first_change_id => $issue->{change_id},
            kind            => 'issue',
            uuid             => $ref->{uuid},     # hard to know this in advance
            project_issue_id => $issue->{id},
            project_id       => $project->{id},
          },
          'get_topic issue ID';

    };

};

run_in_tempdir {
    isa_ok exception { bif() }, 'OptArgs::Usage';
    isa_ok exception { bif( 'init', '--unknown-option' ) }, 'OptArgs::Usage';

    # Check that aliases work
    ok bif(qw/init/),    'init';
    isa_ok bif(qw/lsp/), 'Bif::OK::ListProjects';
    isa_ok bif(qw/ls/),  'Bif::OK::ListTopics';

};

done_testing();
