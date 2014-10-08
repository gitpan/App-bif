use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log identity /) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/ log identity 1/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/log identity 1311/) },
      'Bif::Error::TopicNotFound';

    isa_ok bif(qw/ log identity 1 /), 'Bif::OK::LogIdentity';

};

done_testing();
