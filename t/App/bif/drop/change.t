use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop change /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/drop change 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/drop change c101/) },
      'Bif::Error::ChangeNotFound';

    isa_ok bif(qw/drop change c1/),         'Bif::OK::DropNoForce';
    isa_ok bif(qw/drop change c1 --force/), 'Bif::OK::DropChange';
};

done_testing();
