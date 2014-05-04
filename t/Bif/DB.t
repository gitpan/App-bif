use strict;
use warnings;
use lib 't/lib';
use Bif::DB;
use Bif::DBW;
use Test::Bif;
use Test::More;

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

    # get_topic
    subtest 'get_topic', sub {
        my $ref;
        is_deeply $ref = $db->get_topic(undef), undef, 'get_topic undef';

        is_deeply $ref = $db->get_topic(-1), undef, 'get_topic unknown ID';

        is_deeply $ref = $db->get_topic( $project->{id} ), {
            id              => $project->{id},
            first_update_id => $project->{update_id},
            kind            => 'project',
            uuid             => $ref->{uuid},    # hard to know this in advance
            project_issue_id => undef,
            project_id       => undef,
          },
          'get_topic project ID';

        my ($id) = $db->uuid2id( $ref->{uuid} );
        is $id, $project->{id}, 'uuid2id()';

        is_deeply $ref = $db->get_topic( $task->{id} ), {
            id              => $task->{id},
            first_update_id => $task->{update_id},
            kind            => 'task',
            uuid            => $ref->{uuid},      # hard to know this in advance
            project_issue_id => undef,
            project_id       => undef,
          },
          'get_topic task ID';

        is_deeply $ref = $db->get_topic( $issue->{id} ), {
            id              => $issue->{id},
            first_update_id => $issue->{update_id},
            kind            => 'issue',
            uuid             => $ref->{uuid},     # hard to know this in advance
            project_issue_id => $issue->{id},
            project_id       => $project->{id},
          },
          'get_topic issue ID';

    };

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

    # get_local_hub_id
    subtest 'get_local_hub_id', sub {
        is $db->get_local_hub_id, $hub->{id}, 'get_local_hub_id';
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

    subtest 'get_hub_locations', sub {
        is_deeply [ $db->get_hub_locations ], [], 'get_hub_locations(undef)';
        is_deeply [ $db->get_hub_locations('noalias') ], [],
          'get_hub_locations(q{noalias})';
    };
};

done_testing();
