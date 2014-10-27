use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/pull hub/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/pull hub hub.bif/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/pull hub hub.bif/) }, 'Bif::Error::HubNotFound';

    bif(qw/init hub/);
    isa_ok bif(qw/pull hub hub.bif/), 'Bif::OK::PullHub';

    isa_ok exception { bif(qw/pull hub hub.bif/) }, 'Bif::Error::RepoExists';

    bifcheck;
};

run_in_tempdir {
    bif(qw/init/);
    bif(qw/init hub/);

    bif2(qw/init/);

    my $pinfo = bif2(qw/new project todo title -m m1/);
    bif2(qw/update todo -m m2/);

    my $tinfo = bif2(qw/new task -m m3 -p todo tasktitle/);
    bif2( qw/update/, $tinfo->{id}, qw/-m m4/ );
    my $ref = bif2( qw/sql --noprint/,
        "select uuid from topics where id=$tinfo->{id}" );
    $tinfo->{uuid} = $ref->[0][0];

    $ref = bif2( qw/sql --noprint/,
        "select id from topics where uuid='$tinfo->{uuid}'" );
    is $ref->[0][0], $tinfo->{id}, 'uuid -> id';

    my $iinfo = bif2(qw/new issue -m m5 -p todo issuetitle/);

    bif2( qw/update/, $iinfo->{id}, qw/-m m6/ );
    $ref = bif2( qw/sql --noprint/,
        "select uuid from topics where id=$iinfo->{topic_id}" );
    $iinfo->{uuid} = $ref->[0][0];

    $ref = bif2( qw/sql --noprint/,
        "select id from topics where uuid='$iinfo->{uuid}'" );
    is $ref->[0][0], $iinfo->{topic_id}, 'uuid -> id';

    isa_ok bif2(qw{pull hub ../hub.bif}), 'Bif::OK::PullHub';
    bif2(qw/push project todo hub/);

    isa_ok bif(qw/pull hub hub.bif/), 'Bif::OK::PullHub';
    my $list = bif(qw/list hubs/);
    isa_ok $list, 'Bif::OK::ListHubs';    # TODO need to do better than this

    isa_ok bif(qw{show project hub/todo}), 'Bif::OK::ShowProject';

    $ref = bif( qw/sql --noprint/,
        "select id from topics where uuid='$tinfo->{uuid}'" );
    is $ref->[0][0], undef, 'pull not include tasks';

    $ref = bif( qw/sql --noprint/,
        "select id from topics where uuid='$iinfo->{uuid}'" );
    is $ref->[0][0], undef, 'pull not include issues';

    bifcheck;
};

done_testing();
