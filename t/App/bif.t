use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif() }, qr/usage/, 'usage';
    ok bif(qw/init/), 'init';

    like exception { bif( 'init', '--unknown-option' ) }, qr/usage/,
      'unknown option';

    # Check that aliases work
    isa_ok bif(qw/l/),   'Bif::OK::ListTopics';
    isa_ok bif(qw/lt/),  'Bif::OK::ListTasks';
    isa_ok bif(qw/lts/), 'Bif::OK::ListTasks';
    isa_ok bif(qw/lp/),  'Bif::OK::ListProjects';

};

done_testing();
