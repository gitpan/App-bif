use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ new project todo/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ new project --message m1/) },
      'Bif::Error::ProjectPathRequired';

    isa_ok exception { bif(qw/ new project todo2 title /) },
      'Bif::Error::EmptyContent';

    my $res = bif(qw/ new project todo --message m1 title /);
    isa_ok $res, 'Bif::OK::NewProject';
    ok $res->{id}, 'NewProject ' . $res->{id};

    isa_ok bif(qw/list project-status todo/), 'ARRAY';

    isa_ok exception { bif(qw/ new project todo/) },
      'Bif::Error::ProjectExists';

    subtest dup => sub {
        $res = bif(qw/ new project t2 --dup todo --message m4 /);
        isa_ok $res, 'Bif::OK::NewProject';

        my $t = bif(qw/new task title --message m2/);
        my $i = bif(qw/new issue title --message m3/);

        $res = bif(qw/ new project t3 --dup todo --issues fork --message m5 /);
        isa_ok $res, 'Bif::OK::NewProject';

      TODO: {
            local $TODO = 'not implemented';

            isa_ok exception {
                bif( qw/push issue/, $i->{id},
                    qw/t3 --message m6 --err-on-exists/ );
            }, 'Bif::Error::DestinationExists';
        }
    };
};

done_testing();
