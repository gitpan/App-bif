use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    is_deeply bif(qw/list hubs/), [], 'ListHubs';
};

done_testing();
