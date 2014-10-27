use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    bif(qw/new repo .bifu/);

    {
        isa_ok bif(qw/new identity name email value -m m1 --user-repo --self/),
          'Bif::OK::NewIdentity';
    }

    isa_ok exception { bif(qw/pull identity/) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/pull identity .bifu/) },
      'Bif::Error::RepoNotFound';

    bif(qw/new repo .bif/);

    isa_ok bif(qw/pull identity --self .bifu/), 'Bif::OK::PullIdentity';
    isa_ok bif(qw/show identity 1/),            'Bif::OK::ShowIdentity';

    bifcheck;
};

done_testing();
