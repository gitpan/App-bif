use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    isa_ok bif(qw/list plans/), 'Bif::OK::ListPlansNone';

    bif(qw/new provider name method value --message m1/);
    bif(qw/new plan pname title --message m2/);

    isa_ok bif(qw/list plans/), 'Bif::OK::ListPlans';
};

done_testing();
