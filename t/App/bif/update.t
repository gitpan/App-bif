use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update/) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/update junk/) }, 'Bif::Error::RepoNotFound';

    my $db = bif(qw/init/);

    isa_ok exception { bif(qw/update todo/) }, 'Bif::Error::TopicNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception {
        bif( qw/update /, "$p->{id}.$p->{update_id}", qw/eval/ );
    }, 'Bif::Error::TopicNotFound';

    subtest 'project', sub {

        my $update = bif(qw/update todo --message message/);
        isa_ok $update, 'Bif::OK::UpdateProject';
        ok $update->{update_id}, 'update project';

        $update = bif(qw/update todo eval --message message2/);
        ok $update->{status}->[0], 'update project status';

        my $res = bif(qw/list projects/);
        isa_ok $res, 'Bif::OK::ListProjects';

        # TODO actually check the update effect?

    };

    subtest 'task', sub {

        my $task = bif(qw/new task todo title --message message3/);
        ok $task->{id}, 'create task ' . $task->{id};

        my $update =
          bif( qw/update/, $task->{id}, qw/closed --title title --message m4/ );
        isa_ok $update, 'Bif::OK::UpdateTask';

        isa_ok $update, 'Bif::OK::UpdateTask';
    };

    subtest 'issue', sub {

        my $issue = bif(qw/new issue todo title --message message7/);
        my $update =
          bif( qw/update/, $issue->{id}, qw/closed --title t2 --message m8/ );
        isa_ok $update, 'Bif::OK::UpdateIssue';

    };

};

done_testing();
