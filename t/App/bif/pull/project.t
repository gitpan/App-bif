use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/pull project/) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/pull project todo /) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw{pull project hub/todo}) },
      'Bif::Error::HubNotFound';

    bif(qw/init hub/);
    bif(qw/pull hub hub.bif/);

    isa_ok exception { bif(qw{pull project hub/todo}) },
      'Bif::Error::ProjectNotFound';

    isa_ok exception { bif(qw/pull project todo/) },
      'Bif::Error::ProjectNotFound';

    bif(qw/new project todo title -m message/);
    my $tinfo = bif(qw/new task -m message -p todo tasktitle/);
    my $ref =
      bif( qw/sql --noprint/, "select uuid from topics where id=$tinfo->{id}" );
    $tinfo->{uuid} = $ref->[0][0];

    bif( qw/update/, $tinfo->{id}, qw/-m m2/ );
    bif(qw/push project todo hub -m m3/);

    bif2(qw/init/);
    bif2(qw{pull hub ../hub.bif});

    isa_ok bif2(qw{show project hub/todo}), 'Bif::OK::ShowProject';

    isa_ok exception { bif2( qw/show --uuid/, $tinfo->{uuid} ) },
      'Bif::Error::UuidNotFound';

    #    my $iinfo = bif(qw/new issue -m message -p todo issuetitle/);
    #    bif( qw/update/, $iinfo->{id}, qw/-m m2/ );

    #    isa_ok exception { bif( qw/pull project/, $tinfo->{id}, qw/hub/ ) },
    #      'Bif::Error::ProjectNotFound';;

    isa_ok bif2(qw{pull project hub/todo}), 'Bif::OK::PullProject';

    isa_ok bif2(qw/show todo/), 'Bif::OK::ShowProject';
    isa_ok bif2( qw/show --uuid/, $tinfo->{uuid} ), 'Bif::OK::ShowTask';

    isa_ok bif2(qw{pull project hub/todo}), 'Bif::OK::PullProject';

    bifcheck;
};

done_testing();
