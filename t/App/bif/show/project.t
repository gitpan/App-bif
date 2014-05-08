use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ show project /) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/ show project todo/) },
      'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show project todo /) },
      'Bif::Error::ProjectNotFound';

    my $p1 = bif(qw/ new project todo --message message title /);

    my $show = bif(qw/show project todo/);
    isa_ok( $show, 'Bif::OK::ShowProject' );
};

done_testing();
