use strict;
use warnings;
use lib 't/lib';
use Bif::DB;
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif('init');

    my $project = bif(qw/ new project x title -m message /);
    my $task    = bif(qw/ new task -p x title2 -m message2 /);
    my $issue   = bif(qw/ new issue -p x title3 -m message3 /);
    my $db      = Bif::DB->connect('dbi:SQLite:dbname=.bif/db.sqlite3');
    isa_ok $db, 'Bif::DB::db';

    # path2project

    # get_topic
    subtest 'get_topic', sub {
        my $ref;
        is_deeply $ref = $db->get_topic(undef), undef, 'get_topic undef';

        is_deeply $ref = $db->get_topic(-1), undef, 'get_topic unknown ID';

        is_deeply $ref = $db->get_topic( $project->{id} ), {
            id               => $project->{id},
            first_update_id  => 1,
            kind             => 'project',
            uuid             => $ref->{uuid},     # hard to know this in advance
            project_issue_id => undef,
            project_id       => undef,
          },
          'get_topic project ID';

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

    # get_project
    subtest 'get_project', sub {
        my $ref;
        is_deeply $ref = $db->get_project(undef), undef, 'get_project undef';

        is_deeply $ref = $db->get_project(-1), undef, 'get_project unknown ID';

        is_deeply $ref = $db->get_project( $project->{id} ), undef,
          'get_project ID';
        is_deeply $ref = $db->get_project('unknown'), undef,
          'get_project unknown project';

        is_deeply $ref = $db->get_project('x'), {
            id              => $project->{id},
            first_update_id => 1,
            kind            => 'project',
            uuid            => $ref->{uuid},     # hard to know this in advance
            parent_id       => undef,
            path            => 'x',
          },
          'get_project known project';
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
          $db->status_ids( $project->{id}, 'project', 'run', 'eval' );
        like $ids->[0], qr/^\d+$/, "ids @$ids";
        like $ids->[1], qr/^\d+$/, "ids @$ids";
        is_deeply $invalid, [], "invalid @$invalid";

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', 'run', 'junky', 'eval' );
        like $ids->[0], qr/^\d+$/, "ids @$ids";
        like $ids->[1], qr/^\d+$/, "ids @$ids";
        is_deeply $invalid, ['junky'], "invalid @$invalid";

        ( $ids, $invalid ) =
          $db->status_ids( $project->{id}, 'project', 'more', 'junky', 'eval' );
        like $ids->[0], qr/^\d+$/, "ids @$ids";
        is_deeply $invalid, [ 'junky', 'more' ], "invalid @$invalid";
    };

    subtest 'hub_info', sub {
        is $db->hub_info, undef, 'hub_info(undef)';
    };
};

done_testing();
