use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    my $ref = bif(qw/upgrade/);
    isa_ok $ref, 'Bif::OK::Upgrade';

    # TODO check that something actually happens

    # TODO keep old bif repositories around to run upgrades on
};

done_testing();
