use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    isa_ok bif(qw/new hub name -m m1/),                'Bif::OK::NewHub';
    isa_ok bif(qw/new hub name2 with locatons -m m2/), 'Bif::OK::NewHub';

    bifcheck;
};

done_testing();
