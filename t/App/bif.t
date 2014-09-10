use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    isa_ok exception { bif() }, 'OptArgs::Usage';
    isa_ok exception { bif( 'init', '--unknown-option' ) }, 'OptArgs::Usage';

    # Check that aliases work
    ok bif(qw/init/),    'init';
    isa_ok bif(qw/lsp/), 'Bif::OK::ListProjects';
    isa_ok bif(qw/ls/),  'Bif::OK::ListTopics';

};

done_testing();
