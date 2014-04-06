use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    isa_ok exception { bif(qw/ new task/) }, 'Bif::Error::TitleRequired';

    isa_ok exception { bif(qw/ new task title/) },
      'Bif::Error::NoProjectInRepo';

    isa_ok exception { bif(qw/ new task -p todo title/) },
      'Bif::Error::ProjectNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception { bif(qw/ new task -p todo this is the title/) },
      'Bif::Error::EmptyContent';

    my $i = bif(qw/new task -p todo title -m message/);
    isa_ok $i, 'Bif::OK::NewTask';
    ok $i->{id}, 'task created ' . $i->{id};

    # TODO: check that list tasks shows this task

    isa_ok exception { bif(qw/ new task -p todo title -s unknown/) },
      'Bif::Error::InvalidStatus';

    my $i2 = bif(qw/new task -p todo title -m message2 -s stalled/);
    isa_ok $i2, 'Bif::OK::NewTask';

};

done_testing();
