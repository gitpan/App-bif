use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/reply/) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/reply junk/) }, 'Bif::Error::RepoNotFound';

    my $db = bif(qw/init/);

    isa_ok exception { bif(qw/reply todo/) }, 'Bif::Error::UpdateNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception {
        bif( qw/reply /, "$p->{id}.$p->{update_id}" );
    }, 'Bif::Error::EmptyContent';

    subtest 'project', sub {

        my $update = bif(qw/update todo --message message/);
        isa_ok $update, 'Bif::OK::UpdateProject';
        ok $update->{update_id}, 'update project';

        $update = bif(qw/update todo eval --message message2/);
        ok $update->{status}->[0], 'update project status';

        my $data = bif(qw/list projects/);
        is $data->[0]->[2], 'eval', 'check project update status';

    };

    subtest 'task', sub {

        my $task = bif(qw/new task todo title --message message/);
        ok $task->{id}, 'create task ' . $task->{id};

        my $update = bif( qw/update/, $task->{id}, qw/ --message message2/ );
        isa_ok $update, 'Bif::OK::UpdateTask';
        ok $update->{update_id}, 'update task';

        $update =
          bif( qw/update /, $task->{id}, qw/closed --message message3/ );

        ok $update->{status}->[0], 'update project status';

        my ($status) = $db->xarray(
            select     => 'task_status.status',
            from       => 'tasks',
            inner_join => 'task_status',
            on         => 'task_status.id = tasks.status_id',
            where      => { 'tasks.id' => $task->{id} },
        );

        is $status, 'closed', 'check task update status';

        $update =
          bif( qw/update /, $task->{id}, qw/--title title2 -m message/ );
        my $show = bif( 'show', $task->{id} );
        like $show->[3][1], qr/title2/, 'task title updated';

    };

    subtest 'issue', sub {

        my $issue = bif(qw/new issue todo title --message message/);
        ok $issue->{id}, 'create issue ' . $issue->{id};

        my $update = bif( qw/update/, $issue->{id}, qw/ --message message2/ );

        isa_ok $update, 'Bif::OK::UpdateIssue';
        ok $update->{update_id}, 'update issue';

        $update =
          bif( qw/update /, $issue->{id}, qw/closed --message message3/ );
        ok $update->{status}->[0], 'update issue status';

        my ( $status, $path ) = $db->xarray(
            select     => [ 'issue_status.status', 'projects.path' ],
            from       => 'project_issues',
            inner_join => 'issue_status',
            on         => 'issue_status.id = project_issues.status_id',
            inner_join => 'projects',
            on         => 'projects.id = project_issues.project_id',
            where      => { 'project_issues.id' => $issue->{id} },
        );

        is $status, 'closed', 'check issue update status';
        is $path,   'todo',   'check issue update project';

        $update =
          bif( qw/update /, $issue->{id}, qw/--title title2 -m message/ );
        my $show = bif( 'show', $issue->{id} );

        like $show->[0][1], qr/title2/, 'issue title updated';
    };

};

done_testing();
