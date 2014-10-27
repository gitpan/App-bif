use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log hub/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ log hub junk/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ log hub junk/) }, 'Bif::Error::HubNotFound';

    bif(qw/init localhub/);
    bif(qw/pull hub localhub.bif/);

    isa_ok bif(qw/log hub localhub/), 'Bif::OK::LogHub';

};

done_testing();
