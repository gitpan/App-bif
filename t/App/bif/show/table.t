use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ show table /) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ show table topics/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show table unknown /) },
      'Bif::Error::TableNotFound';

    isa_ok bif(qw/ show table topics/),        'Bif::OK::ShowTable';
    isa_ok bif(qw/ show table topics --full/), 'Bif::OK::ShowFullTable';

};

done_testing();
