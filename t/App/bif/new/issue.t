use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    isa_ok exception { bif(qw/ new issue /) }, 'Bif::Error::TitleRequired';

    isa_ok exception { bif(qw/ new issue title/) },
      'Bif::Error::NoProjectInRepo';

    isa_ok exception { bif(qw/ new issue -p todo title/) },
      'Bif::Error::ProjectNotFound';

    my $p = bif(qw/ new project todo --message m1 title /);

    isa_ok exception { bif(qw/ new issue -p todo this is the title/) },
      'Bif::Error::EmptyContent';

    my $i = bif(qw/new issue -p todo title -m m2/);
    isa_ok $i, 'Bif::OK::NewIssue';

    isa_ok exception { bif(qw/ new issue -p todo title -s unknown/) },
      'Bif::Error::InvalidStatus';

    my $i2 = bif(qw/new issue -p todo title -m m3 -s stalled/);
    isa_ok $i2, 'Bif::OK::NewIssue';

    bifcheck;
};

done_testing();
