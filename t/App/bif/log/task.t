use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log task /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/ log task 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/log task 1311/) }, 'Bif::Error::TopicNotFound';

    my $p1 = bif(qw/ new project todo --message m1 title /);

    isa_ok exception { bif( qw/ log task /, $p1->{id} ) },
      'Bif::Error::WrongKind';

    my $i1 = bif(qw/new task title -m m2 /);

    isa_ok bif( qw/ log task /, $i1->{id} ), 'Bif::OK::LogTask';

};

done_testing();
