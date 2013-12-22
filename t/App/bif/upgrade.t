use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    isa_ok bif(qw/init/), 'Bif::DB::RW::db';

    my $ref = bif(qw/upgrade/);

    ok $ref->[1] >= $ref->[0], 'upgraded';

    # TODO keep old bif repositories around to run upgrades on
};

done_testing();
