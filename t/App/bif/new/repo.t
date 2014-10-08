use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    isa_ok exception { bif(qw/new repo/) }, 'OptArgs::Usage';

    isa_ok bif(qw/new repo x/), 'Bif::OK::NewRepo';
    ok !path('x')->child('config')->exists, 'no config file';

    isa_ok bif(qw/new repo x2 --config/), 'Bif::OK::NewRepo';
    ok path('x2')->child('config')->exists, '--config';

    isa_ok exception { bif(qw/new repo x/) }, 'Bif::Error::DirExists';
};

done_testing();
