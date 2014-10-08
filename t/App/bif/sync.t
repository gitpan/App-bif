use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/sync/) }, 'Bif::Error::UserRepoNotFound';
    bif(qw/init/);
    isa_ok exception { bif(qw/sync/) }, 'Bif::Error::SyncNone';

    bif(qw/init hub/);
    bif(qw/pull hub hub/);

    bif2(qw/init/);
    bif2(qw!pull hub ../hub!);

    isa_ok bif(qw/sync/), 'Bif::OK::Sync';
    isa_ok exception { bif(qw{show project hub/todo}) },
      'Bif::Error::ProjectNotFound';

    my $pinfo = bif(qw/new project todo title -m m1/);
    bif(qw/push project todo hub/);

    isa_ok bif2(qw/sync -m m2/), 'Bif::OK::Sync';

    isa_ok bif2(qw{show project hub/todo}), 'Bif::OK::ShowProject';

    bif2(qw{pull project hub/todo});

    #    bif(qw/update todo -m m3a/);
    #    bif2(qw/update todo -m m3b/);
    #    isa_ok bif(qw/sync -m m5/),  'Bif::OK::Sync';
    #    isa_ok bif2(qw/sync -m m4/), 'Bif::OK::Sync';

    subtest 'task sync' => sub {
        my $tinfo = bif2(qw/new task -m m6 -p todo tasktitle/);
        my $x     = bif2( qw/sql --noprint/,
            qq{select uuid from topics where id=$tinfo->{id}} );
        $tinfo->{uuid} = $x->[0][0];
        isa_ok bif2(qw/sync -m m12/), 'Bif::OK::Sync';

        isa_ok bif(qw/sync -m m11/), 'Bif::OK::Sync';
        my $ref2 = bif( qw/sql --noprint/,
            qq{select 1 from topics where uuid="$tinfo->{uuid}"} );
        ok $ref2->[0][0], 'task sync';

        #        bif( qw/update/, $tinfo->{id}, qw/-m m7/ );
        my $u = bif( qw/update --uuid/, $tinfo->{uuid}, qw/-m m12b/ );
        $x = bif( qw/sql --noprint/,
            qq{select uuid from changes where id=$u->{change_id}} );
        $u->{uuid} = $x->[0][0];
        bif(qw/sync/);

        bif2(qw/sync/);
        $ref2 = bif2( qw/sql --noprint/,
            qq{select 1 from changes where uuid="$u->{uuid}"} );
        ok $ref2->[0][0], 'task change sync';
    };

    subtest 'issue sync' => sub {
        my $iinfo = bif2(qw/new issue -m m8 -p todo issuetitle/);
        my $x     = bif2( qw/sql --noprint/,
            qq{select uuid from topics where id=$iinfo->{topic_id}} );
        $iinfo->{uuid} = $x->[0][0];
        bif2( qw/update/, $iinfo->{id}, qw/-m m10/ );
        isa_ok bif2(qw/sync -m m13/), 'Bif::OK::Sync';
        isa_ok bif(qw/sync -m m14/),  'Bif::OK::Sync';
        my $ref1 = bif( qw/sql --noprint/,
            qq{select 1 from topics where uuid="$iinfo->{uuid}"} );
        ok $ref1->[0][0], 'issue sync';
    };

    my $ref1 = bif(
        qw/sql --noprint/,
        qq{select hash from hub_related_projects order by
        hub_id,project_id}
    );
    my $ref2 = bif2(
        qw/sql --noprint/,
        qq{select hash from hub_related_projects order by
        hub_id,project_id}
    );

    ok $ref1->[0][0] eq $ref2->[0][0], "$ref1->[0][0] eq $ref2->[0][0]";

};

done_testing();
