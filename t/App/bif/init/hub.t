use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    isa_ok exception { bif(qw/init hub/) }, 'OptArgs::Usage';

    isa_ok bif(qw/init hub x -m m1/), 'Bif::OK::InitHub';
};

done_testing();
