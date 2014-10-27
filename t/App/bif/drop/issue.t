use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop issue /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/drop issue 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/drop issue 101/) }, 'Bif::Error::TopicNotFound';

    bif(qw/new project todo title -m m1/);
    my $t = bif(qw/new issue title -p todo -m 2/);

    isa_ok bif( qw/drop issue/,         $t->{id} ), 'Bif::OK::DropNoForce';
    isa_ok bif( qw/drop issue --force/, $t->{id} ), 'Bif::OK::DropIssue';

    bifcheck;
};

done_testing();
