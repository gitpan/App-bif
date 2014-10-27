use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop task /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/drop task 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/drop task 101/) }, 'Bif::Error::TopicNotFound';

    bif(qw/new project todo title -m m1/);
    my $t = bif(qw/new task title -p todo -m 2/);

    isa_ok bif( qw/drop task/,         $t->{id} ), 'Bif::OK::DropNoForce';
    isa_ok bif( qw/drop task --force/, $t->{id} ), 'Bif::OK::DropTask';

    bifcheck;
};

done_testing();
