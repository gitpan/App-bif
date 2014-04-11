use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    debug_on;
    my $res = bif(qw/ new project todo --message message title /);
    isa_ok $res, 'Bif::OK::NewProject';
    ok $res->{id}, 'NewProject ' . $res->{id};

    isa_ok bif(qw/list project-status todo/), 'ARRAY';

    isa_ok exception { bif(qw/ new project todo/) },
      'Bif::Error::ProjectExists';

    isa_ok exception { bif(qw/ new project --message message/) },
      'Bif::Error::ProjectPathRequired';

    isa_ok exception { bif(qw/ new project todo2 title /) },
      'Bif::Error::EmptyContent';
};

done_testing();
