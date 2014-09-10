use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    isa_ok exception { bif(qw/init repo/) }, 'OptArgs::Usage';

    isa_ok bif(qw/init repo x/), 'Bif::OK::InitRepo';
    ok !path('x')->child('config')->exists, 'no config file';

    isa_ok bif(qw/init repo x2 --config/), 'Bif::OK::InitRepo';
    ok path('x2')->child('config')->exists, '--config';

    isa_ok exception { bif(qw/init repo x/) }, 'Bif::Error::DirExists';
};

done_testing();
