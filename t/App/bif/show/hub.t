use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ show hub /) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ show hub local/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show hub unknown /) }, 'Bif::Error::HubNotFound';

    bif(qw/init myhub/);
    bif(qw/pull hub myhub/);

    isa_ok bif(qw/ show hub myhub/), 'Bif::OK::ShowHub';

};

done_testing();
