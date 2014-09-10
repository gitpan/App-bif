use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    bif(qw/new provider name method value --message m1/);

    isa_ok exception { bif(qw/new host name extra/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/new host unknown:name/) },
      'Bif::Error::ProviderNotFound';

    isa_ok bif(qw/new host pname --message m2/),       'Bif::OK::NewHost';
    isa_ok bif(qw/new host name:pname2 --message m3/), 'Bif::OK::NewHost';

    bif(qw/new provider name2 method value --message m4/);

    isa_ok exception { bif(qw/new host name3/) },
      'Bif::Error::AmbiguousProvider';
};

done_testing();
