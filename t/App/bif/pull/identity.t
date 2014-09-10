use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    my $repo = path(qw/x/);
    bif( qw/init repo/, $repo );

    {
        local $CWD = $repo;
        isa_ok bif(qw/new identity name email value -m m1 --self/),
          'Bif::OK::NewIdentity';
    }

    isa_ok exception { bif(qw/pull identity/) }, 'OptArgs::Usage';
    isa_ok exception { bif( qw/pull identity/, $repo ) },
      'Bif::Error::RepoNotFound';

    bif(qw/init repo .bif/);

    isa_ok bif( qw/pull identity/, $repo ), 'Bif::OK::PullIdentity';
    isa_ok bif(qw/show identity 1/), 'Bif::OK::ShowIdentity';
};

done_testing();
