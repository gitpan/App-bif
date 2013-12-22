use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ push /) },   qr/usage:/, 'usage';
    like exception { bif(qw/ push 1 /) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/ push 1 todo2/) }, 'Bif::Error::RepoNotFound';

    my $db = bif(qw/init/);

    my $p1 = bif(qw/ new project todo --message message title /);

    isa_ok exception { bif(qw/ push 99999 todo2/) },
      'Bif::Error::TopicNotFound';

    isa_ok exception { bif(qw/ push todo todo2/) }, 'Bif::Error::TopicNotFound';

    subtest 'issue', sub {
        my $i1 = bif(qw/ new issue todo --message message title --mtime 100/);

        isa_ok exception { bif( qw/push/, $i1->{id}, qw/todo2/ ) },
          'Bif::Error::ProjectNotFound';

        isa_ok exception { bif( qw/push/, $i1->{id}, qw/todo/ ) },
          'Bif::Error::AlreadyPushed';

        my $p2 = bif(qw/ new project todo2 --message message title /);

        my $res = bif( 'push', $i1->{id}, qw/todo2 --message message/ );
        ok $res->{update_id}, 'have update_id ' . $res->{update_id};

        is_deeply [
            $db->xarrays(
                select     => 'projects.path',
                from       => 'project_issues',
                inner_join => 'projects',
                on         => 'projects.id = project_issues.project_id',
                where      => { 'project_issues.issue_id' => $i1->{id} },
                order_by   => 'path',
            )
          ],
          [ ['todo'], ['todo2'] ], 'in two projects';
    };

    # TODO what happens with tasks?!? Copy? Move? Copy + Depend?
    # What happens with tasks on "new project --fork"?
};

done_testing();
