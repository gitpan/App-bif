use strict;
use warnings;
use lib 't/lib';
use Log::Any::Test;
use App::bif::Context;
use File::chdir;
use Log::Any qw/$log/;
use Path::Tiny qw/path tempfile cwd/;
use Term::ANSIColor qw/color/;
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

subtest 'App::bif::Context', sub {

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

    subtest 'repo', sub {
        run_in_tempdir {
            my $ctx = App::bif::Context->new( {} );
            isa_ok exception { $ctx->repo }, 'Bif::Error::RepoNotFound';

            my $repo = cwd->child('.bif');
            mkdir $repo;
            $ctx = App::bif::Context->new( {} );
            is $ctx->repo, $repo, 'repo .bif';

            mkdir 'subdir';
            local $CWD = 'subdir';
            $ctx = App::bif::Context->new( {} );
            is $ctx->repo, $repo, 'repo ../.bif';

            my $repo2 = cwd->child('.bif');
            mkdir $repo2;
            $ctx = App::bif::Context->new( {} );
            is $ctx->repo, $repo2, 'found current with parent repo existing';
        };
    };

    subtest 'conf', sub {
        run_in_tempdir {
            my $ctx = App::bif::Context->new( {} );
            my $userconf = path( $ctx->{_bif_user_config} );
            $userconf->spew("option1 = 1\noption2 = 1\n");

            $ctx = App::bif::Context->new( {} );
            is $ctx->{option1}, 1, 'user config';
            is $ctx->{option2}, 1, 'user config';

            my $bifdir = path('.bif');
            $bifdir->mkpath;
            $bifdir->child('config')->spew("option2 = 2\n");

            $ctx = App::bif::Context->new( {} );
            is $ctx->{option1}, 1, 'repo config';
            is $ctx->{option2}, 2, 'repo config';
        };
    };

    subtest 'db', sub {
        run_in_tempdir {
            my $ctx = App::bif::Context->new( {} );
            isa_ok exception { $ctx->db }, 'Bif::Error::RepoNotFound';

            mkdir '.bif';
            $ctx = App::bif::Context->new( {} );
            my $db = $ctx->db;
            isa_ok $db, 'Bif::DB::db';

            like exception { $db->do('select sha(1)') }, qr/no such function/,
              'read-only';
        };
    };

    subtest '$ctx->dbw', sub {
        run_in_tempdir {
            my $ctx = App::bif::Context->new( {} );
            isa_ok exception { $ctx->dbw }, 'Bif::Error::RepoNotFound';

            mkdir '.bif';
            $ctx = App::bif::Context->new( {} );
            my $dbw = $ctx->dbw;
            isa_ok $dbw, 'Bif::DBW::db';
            my $sha1 = Digest::SHA::sha1_hex(1);
            my ($sha) = $dbw->selectrow_array('select sha1_hex(1)');
            is $sha, $sha1, 'read-write';
        };
    };

    subtest '$ctx->uuid2id', sub {
        run_in_tempdir {
            my $ctx = App::bif::Context->new( {} );
            is 1, $ctx->uuid2id(1), 'uuid2id with no uuid';
            $ctx->{uuid}++;
            isa_ok exception { $ctx->uuid2id(1) }, 'Bif::Error::RepoNotFound';
        };
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

    subtest 'get_topic', sub {
        my $dbw = $ctx->dbw;
        $dbw->txn(
            sub {
                my $update  = new_test_update($dbw);
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
                    id              => $issue->{id},
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
