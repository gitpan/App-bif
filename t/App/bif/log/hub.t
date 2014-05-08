use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log hub/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ log hub local/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok bif(qw/log hub local/), 'Bif::OK::LogHub';

    isa_ok exception { bif(qw/ log hub unknown /) }, 'Bif::Error::HubNotFound';

};

done_testing();
