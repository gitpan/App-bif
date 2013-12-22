use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif() }, qr/usage/, 'usage';
    ok bif(qw/init/), 'init';

    # Check that aliases work
    is_deeply bif(qw/lt/),  [], 'lt';
    is_deeply bif(qw/lts/), [], 'lts';
    is_deeply bif(qw/lp/),  [], 'lp';

    ok bif(qw/new project todo title --message m/), 'new project';

    # very weak test I know.... TODO
    isa_ok bif(qw/lp/), 'ARRAY', 'lp';

    ok bif(qw/new issue todo title --message m/), 'new issue';

    # very weak test I know.... TODO
    isa_ok bif(qw/lt/), 'ARRAY', 'active with contents';

};

done_testing();
