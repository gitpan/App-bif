use strict;
use warnings;
use lib 't/lib';
use Bif::DB;
use Bif::DBW;
use Test::Bif;
use Test::More skip_all => 'identity changes broke everything';

run_in_tempdir {

    my $dbw = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    my ( $hub, $update, $project, $ps, $ts, $is, $task, $issue );
    $dbw->txn(
        sub {
            $dbw->deploy;

            $hub = new_test_hub( $dbw, 1 );

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $update  = new_test_update($dbw);
            $project = new_test_project($dbw);

            $ps = new_test_project_status( $dbw, $project );
            $ts = new_test_task_status( $dbw, $project );
            $is = new_test_issue_status( $dbw, $project );
            $task = new_test_task( $dbw, $ts );
            $issue = new_test_issue( $dbw, $is );
            $dbw->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $project->{id},
                    update_id => $update->{id},
                    status_id => $ps->{id},
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    my $db = Bif::DB->connect('dbi:SQLite:dbname=db.sqlite3');
    isa_ok $db, 'Bif::DB::db';

    # get_update
    subtest 'get_update', sub {
        my $ref;
        is_deeply $ref = $db->get_update(undef), undef, 'get_update undef';

        is_deeply $ref = $db->get_update( $project->{id} ), undef,
          'get_update topic ID';

        is_deeply $ref = $db->get_update("$project->{id}.1243566789"),
          undef,
          'get_update ID.unknown';

        is_deeply $ref =
          $db->get_update("$project->{id}.$project->{update_id}"), {
            id         => $project->{id},
            kind       => 'project',
            uuid       => $ref->{uuid},           # hard to know this in advance
            update_id  => $project->{update_id},
            project_id => undef,
            project_issue_id => undef,
          },
          'get_update ID.UPDATE_ID';

        is_deeply $ref =
          $db->get_update("$project->{id}.$project->{update_id}"), {
            id         => $project->{id},
            kind       => 'project',
            uuid       => $ref->{uuid},           # hard to know this in advance
            update_id  => $project->{update_id},
            project_id => undef,
            project_issue_id => undef,
          },
          'get_update project ID.UPDATE_ID';

        is_deeply $ref = $db->get_update("$task->{id}.$task->{update_id}"), {
            id         => $task->{id},
            kind       => 'task',
            uuid       => $ref->{uuid},           # hard to know this in advance
            update_id  => $task->{update_id},
            project_id => undef,
            project_issue_id => undef,
          },
          'get_update task ID.UPDATE_ID';

        is_deeply $ref = $db->get_update("$issue->{id}.$issue->{update_id}"), {
            id         => $issue->{id},
            kind       => 'issue',
            uuid       => $ref->{uuid},           # hard to know this in advance
            update_id  => $issue->{update_id},
            project_id => $project->{id},
            project_issue_id => $issue->{id},
          },
          'get_update issue ID.UPDATE_ID';

      TODO: {
            local $TODO = "No easy way to match update/topic IDs";
            is_deeply $ref =
              $db->get_update("$project->{id}.$task->{update_id}"), undef,
              'get_update bad ID/UPDATE_ID combo';

        }
    };

    # get_localhub_id
    subtest 'get_localhub_id', sub {
        is $db->get_localhub_id, $hub->{id}, 'get_localhub_id';
    };

    # get_projects
    subtest 'get_projects', sub {
        my @ref = $db->get_projects(undef);
        is_deeply \@ref, [], 'get_projects undef';

        @ref = $db->get_projects(-1);
        is_deeply \@ref, [], 'get_projects unknown ID';

        @ref = $db->get_projects( $project->{id} );
        is_deeply \@ref, [], 'get_projects ID';

        @ref = $db->get_projects('unknown');
        is_deeply \@ref, [], 'get_projects unknown project';

        @ref = $db->get_projects( $project->{name} );

        is_deeply \@ref, [
            {
                id              => $project->{id},
                first_update_id => $project->{update_id},
                kind            => 'project',
                uuid      => $ref[0]->{uuid},    # hard to know this in advance
                parent_id => undef,
                path      => $project->{name},
                local     => 1,
            }
          ],
          'get_projects known project';

        # TODO get project with repo
    };

    # status_ids
    subtest 'status_ids', sub {
        my ( $ids, $invalid );

        ( $ids, $invalid ) = $db->status_ids();
        is_deeply $ids,     [], 'ids no args';
        is_deeply $invalid, [], 'invalid no args';

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', undef );
        is_deeply $ids,     [], 'ids undefined args';
        is_deeply $invalid, [], 'invalid undefined args';

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', $ps->{status} );
        is $ids->[0], $ps->{id}, "ids @$ids";
        is_deeply $invalid, [], "invalid @$invalid";

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', $ps->{status}, 'junky' );

        is $ids->[0], $ps->{id}, "ids @$ids";
        is_deeply $invalid, ['junky'], "invalid @$invalid";

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', 'more', 'junky',
            $ps->{status}, $ps->{status} );
        is_deeply $ids, [ $ps->{id} ], "ids @$ids";    # Multiples get reduced
        is_deeply $invalid, [ 'junky', 'more' ], "invalid @$invalid";

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'task', 'more', $ts->{status},
            'junky' );
        is_deeply $ids, [ $ts->{id} ], "ids @$ids";
        is_deeply $invalid, [ 'junky', 'more' ], "invalid @$invalid";

        is_deeply $invalid, [ 'junky', 'more' ], "invalid @$invalid";
        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'issue', 'more', $is->{status},
            'junky' );
        is_deeply $ids, [ $is->{id} ], "ids @$ids";
        is_deeply $invalid, [ 'junky', 'more' ], "invalid @$invalid";
    };

    subtest 'get_hub_repos', sub {
        is_deeply [ $db->get_hub_repos ], [], 'get_hub_repos(undef)';
        is_deeply [ $db->get_hub_repos('noname') ], [],
          'get_hub_repos(q{noname})';
    };
};

done_testing();
