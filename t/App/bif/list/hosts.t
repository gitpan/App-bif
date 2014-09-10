use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    isa_ok bif(qw/list hosts/), 'Bif::OK::ListHostsNone';

    bif(qw/new provider name method value/);
    bif(qw/new host pname/);

    isa_ok bif(qw/list hosts/), 'Bif::OK::ListHosts';
};

done_testing();
