use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok bif(qw/init/), 'Bif::OK::Init';
    isa_ok exception { bif(qw/init/) }, 'Bif::Error::DirExists';

    isa_ok bif(qw/init other/), 'Bif::OK::Init';
    isa_ok exception { bif(qw/init other/) }, 'Bif::Error::DirExists';
};

done_testing();
