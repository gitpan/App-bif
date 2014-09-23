use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update project/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/update project 100/) },
      'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/update project 100/) },
      'Bif::Error::ProjectNotFound';

  TODO: {
        local $TODO = 'fix get_project at some stage';
        isa_ok exception { bif( qw/update project 1/, ); },
          'Bif::Error::WrongKind';
    }

    my $p = bif(qw/ new project todo title --message m1 /);
    my $u =
      bif( qw/update project todo/, qw/closed --title title --message m4/ );

    isa_ok $u, 'Bif::OK::ChangeProject';
};

done_testing();
