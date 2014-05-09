use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif() }, 'OptArgs::Usage';
    debug_on if $^O eq 'MacOS';
    ok bif(qw/init/), 'init';

    like exception { bif( 'init', '--unknown-option' ) }, qr/usage/,
      'unknown option';

    # Check that aliases work
    isa_ok bif(qw/ls/), 'Bif::OK::ListProjects';
    isa_ok bif(qw/ll/), 'Bif::OK::ListTopics';

};

done_testing();
