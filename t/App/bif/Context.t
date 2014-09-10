use strict;
use warnings;
use lib 't/lib';
use Log::Any::Test;
use App::bif::Context;
use File::chdir;
use Log::Any qw/$log/;
use Path::Tiny qw/path cwd/;
use Test::Bif;
use Test::More;
use Test::Fatal qw/exception/;

#open STDOUT, '>', \my $out;

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
        like exception { App::bif::Context->new },
          qr/missing ref/, 'App::bif::Context->new no arg';

        my $ctx = App::bif::Context->new( { no_color => 1 } );
        isa_ok $ctx, 'App::bif::Context';

        # When testing anything related to debug it is important to specify
        # 'no_pager', otherwise you'll spend ages looking for an issue in
        # IO::Pager. The Test::Bif functions normally take care of this for
        # us.
        App::bif::Context->new( { debug => 1, no_pager => 1 } );
        $log->contains_ok( qr/ctx:/, 'debugging on' );
    };

    my $ctx = App::bif::Context->new( {} );

    # color - not tested

    subtest 'err', sub {
        my $e = exception { $ctx->err( 'Token', 'text' ) };
        isa_ok $e, "Bif::Error::Token";
        like $e, qr/fatal:.*text/, 'fatal text';
        like exception {
            $ctx->err( 'Token', 'text %d %s', 1, 'a string' );
        }, qr/fatal:.*text 1 a string/, 'fatal text interpolation';
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
        isa_ok exception { $ctx->repo },      'Bif::Error::RepoNotFound';
        isa_ok exception { $ctx->db },        'Bif::Error::RepoNotFound';
        isa_ok exception { $ctx->dbw },       'Bif::Error::RepoNotFound';
    };

    bif(qw/init/);
    $ctx = App::bif::Context->new( {} );

    subtest 'repo', sub {
        isa_ok $ctx->repo, 'Path::Tiny';

        mkdir 'subdir';
        local $CWD = 'subdir';
        my $ctx2 = App::bif::Context->new( {} );
        is $ctx2->repo, $ctx->repo, 'subdir';

        bif('init');
        my $ctx3 = App::bif::Context->new( {} );
        is $ctx3->repo, $ctx->repo->parent->child(qw/subdir .bif/),
          'subdir repo';
    };

    #    subtest 'config', sub {
    #        ok $ctx->{'user.alias'}->{ls}, $ctx->{'user.alias'}->{ls};
    #    };

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
        $ctx->{uuid}++;
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
----------
apple  1.3
END

        is $ctx->render_table(
            'l r',
            [ 'Item', 'Cost' ],
            [ [ 'apple', 1.3 ] ], 1
          ),
          <<"END", 'render_table ok';
 Item  Cost
 ----------
 apple  1.3
END

    };

    subtest 'prompt_edit', sub {

        isa_ok exception { $ctx->prompt_edit }, 'Bif::Error::EmptyContent';

        is $ctx->prompt_edit( val => 'Not empty' ), "Not empty\n",
          'prompt_edit not empty';
    };

    subtest 'get_update', sub {
        my $dbw = $ctx->dbw;
        $dbw->txn(
            sub {
                is $ctx->get_update(undef), undef, 'undef';

                isa_ok exception { $ctx->get_update('not a uID') },
                  'Bif::Error::UpdateNotFound';

                isa_ok exception { $ctx->get_update(1000000) },
                  'Bif::Error::UpdateNotFound';

                isa_ok exception { $ctx->get_update('u1000000') },
                  'Bif::Error::UpdateNotFound';

                my $uid = $ctx->new_update( action => 'junk', );

                my $res = $ctx->get_update( 'u' . $uid );
                is $res->{id}, $uid, 'uid found';

                $dbw->rollback;
            }
        );
    };

    subtest 'get_topic', sub {
        my $dbw = $ctx->dbw;
        $dbw->txn(
            sub {
                my $uid = $ctx->new_update( action => 'junk', );
                my $project = new_test_project($dbw);

                my $ps = new_test_project_status( $dbw, $project );
                my $ts = new_test_task_status( $dbw, $project );
                my $is = new_test_issue_status( $dbw, $project );
                my $task = new_test_task( $dbw, $ts );
                my $issue = new_test_issue( $dbw, $is );

                my $ref;

                isa_ok exception { $ctx->get_topic(-1) },
                  'Bif::Error::TopicNotFound';

                is_deeply $ref = $ctx->get_topic( $project->{id} ), {
                    id              => $project->{id},
                    first_update_id => $project->{update_id},
                    kind            => 'project',
                    uuid => $ref->{uuid},    # hard to know this in advance
                    project_issue_id => undef,
                    project_id       => undef,
                  },
                  'get_topic project ID';

                my @ids = $dbw->uuid2id( $ref->{uuid} );
                is_deeply \@ids, [ [ $project->{id} ] ], 'uuid2id()';

                @ids = $dbw->uuid2id( substr( $ref->{uuid}, 0, 13 ) );
                is_deeply \@ids, [ [ $project->{id} ] ], 'uuid2id() partial';

                is_deeply $ref = $ctx->get_topic( $task->{id} ), {
                    id              => $task->{id},
                    first_update_id => $task->{update_id},
                    kind            => 'task',
                    uuid => $ref->{uuid},    # hard to know this in advance
                    project_issue_id => undef,
                    project_id       => undef,
                  },
                  'get_topic task ID';

                is_deeply $ref = $ctx->get_topic( $issue->{id} ), {
                    id              => $issue->{topic_id},
                    first_update_id => $issue->{update_id},
                    kind            => 'issue',
                    uuid => $ref->{uuid},    # hard to know this in advance
                    project_issue_id => $issue->{id},
                    project_id       => $project->{id},
                  },
                  'get_topic issue ID';

                $dbw->rollback;
            }
        );
    };

};

done_testing();
