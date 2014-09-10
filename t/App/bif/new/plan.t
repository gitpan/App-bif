use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/init/);
    bif(qw/new provider name method value --message m1/);

    isa_ok exception { bif(qw/new plan name/) }, 'Bif::Error::TitleRequired';

    isa_ok exception { bif(qw/new plan unknown:name title/) },
      'Bif::Error::ProviderNotFound';

    isa_ok bif(qw/new plan pname title --message m2/),       'Bif::OK::NewPlan';
    isa_ok bif(qw/new plan name:pname2 title --message m3/), 'Bif::OK::NewPlan';

    bif(qw/new provider name2 method value --message m4/);

    isa_ok exception { bif(qw/new plan name3 title/) },
      'Bif::Error::AmbiguousProvider';
};

done_testing();
