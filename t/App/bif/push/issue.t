use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ push issue/) },    qr/usage:/, 'usage';
    like exception { bif(qw/ push issue 1 /) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/ push issue 1 todo2/) },
      'Bif::Error::RepoNotFound';

    bif(qw/init/);

    my $p1 = bif(qw/ new project todo title --message m1 /);

    isa_ok exception { bif(qw/ push issue 99999 todo/) },
      'Bif::Error::TopicNotFound';

    my $i1 = bif(qw/ new issue title --message m2 /);

    isa_ok exception { bif( qw/push issue/, $i1->{id}, qw/todo2/ ) },
      'Bif::Error::ProjectNotFound';

    isa_ok bif( qw/push issue/, $i1->{id}, qw/todo -m m3/ ),
      'Bif::OK::PushIssue', 'already pushed';

    isa_ok exception {
        bif( qw/push issue/, $i1->{id}, qw/todo --err-on-exists -m m4/ );
    }, 'Bif::Error::DestinationExists';

    my $p2 = bif(qw/ new project todo2 title --message m5 /);

    my $res = bif( qw/push issue/, $i1->{id}, qw/todo2 --message m6/ );
    isa_ok $res, 'Bif::OK::PushIssue';

};

done_testing();
