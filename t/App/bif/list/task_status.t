use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/list task-status/) }, qr/^usage:/, 'usage';

    bif(qw/init/);
    bif(qw/ new project todo --message message title /);

    isa_ok bif(qw/list task-status todo/), 'ARRAY';

    isa_ok exception { bif(qw/list task-status noproject/) },
      'Bif::Error::ProjectNotFound';
};

done_testing();
