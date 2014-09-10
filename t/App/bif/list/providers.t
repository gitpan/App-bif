use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    isa_ok bif(qw/list providers/), 'Bif::OK::ListProvidersNone';

    bif(qw/new provider name method value/);
    isa_ok bif(qw/list providers/), 'Bif::OK::ListProviders';
};

done_testing();
