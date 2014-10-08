use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log project /) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/ log project 1/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/log project 1311/) },
      'Bif::Error::ProjectNotFound';

    my $p1 = bif(qw/ new project todo --message m1 title /);

    isa_ok bif(qw/ log project todo /), 'Bif::OK::LogProject';

    # TODO    isa_ok bif( qw/ log project /, $p1->{id} ), 'Bif::OK::LogProject';

};

done_testing();
