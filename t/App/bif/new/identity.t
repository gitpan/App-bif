use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ new identity/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/new repo .bifu/);

    isa_ok exception { bif(qw/ new identity/) }, 'Bif::Error::RepoNotFound';

    bif(qw/new repo .bif/);

    isa_ok exception { bif(qw/ new identity name method value -m m1/) },
      'Bif::Error::NoSelfIdentity';

    isa_ok bif(qw/ new identity self method value --self -m m2/),
      'Bif::OK::NewIdentity';

    isa_ok bif(qw/ new identity name method value -m m3/),
      'Bif::OK::NewIdentity';

    bifcheck;
};

done_testing();
