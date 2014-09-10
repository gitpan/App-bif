use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);

    isa_ok exception { bif(qw/new provider name method value extra/) },
      'OptArgs::Usage';

    isa_ok bif(qw/new provider name method value/), 'Bif::OK::NewProvider';
};

done_testing();
