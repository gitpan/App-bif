use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    isa_ok bif(qw/list hubs/), 'Bif::OK::ListHubs';
};

done_testing();
