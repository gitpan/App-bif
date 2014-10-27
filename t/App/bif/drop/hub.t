use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop hub /) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/drop hub nohub/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);
    bif(qw/init hub/);

    isa_ok exception { bif(qw/drop hub hub/) }, 'Bif::Error::HubNotFound';
    bif(qw/pull hub hub.bif/);

    isa_ok bif(qw/drop hub hub/),    'Bif::OK::DropNoForce';
    isa_ok bif(qw/drop hub hub -f/), 'Bif::OK::DropHub';
    isa_ok exception { bif(qw/show hub hub/) }, 'Bif::Error::HubNotFound';

    bifcheck;
};

done_testing();
