use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop update /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/drop update 1/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/drop update u101/) },
      'Bif::Error::UpdateNotFound';

    isa_ok bif(qw/drop update u1/),         'Bif::OK::DropNoForce';
    isa_ok bif(qw/drop update u1 --force/), 'Bif::OK::DropUpdate';
};

done_testing();
