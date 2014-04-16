use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

sub bif2 {
    local $CWD = 'bif2';
    bif(@_);
}

run_in_tempdir {

    isa_ok exception { bif(qw/sync/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/sync/) }, 'Bif::Error::SyncNone';

    bif(qw/init bif2/);
    bif(qw/init hub --bare/);
    bif(qw/register hub/);
    isa_ok bif(qw/sync/), 'Bif::OK::Sync';
    isa_ok exception { bif(qw/show todo hub/) }, 'Bif::Error::TopicNotFound';

    bif2(qw!register ../hub!);
    my $pinfo = bif2(qw/new project todo title -m m1/);
    bif2(qw/export todo hub/);

    isa_ok bif(qw/sync -m m2/), 'Bif::OK::Sync';
    isa_ok exception { bif(qw/show todo/) }, 'Bif::Error::TopicNotFound';
    isa_ok bif(qw/show todo hub/), 'Bif::OK::ShowProject';

    bif2(qw/update todo -m m3/);

    my $ref1 =
      bif( qw/sql --noprint/, qq{select hash from projects order by id} );
    my $ref2 =
      bif2( qw/sql --noprint/, qq{select hash from projects order by id} );

    ok $ref1->[0][0] ne $ref2->[0][0], "$ref1->[0][0] ne $ref2->[0][0]";

    bif(qw/import todo hub/);
    isa_ok bif2(qw/sync -m m4/), 'Bif::OK::Sync';
    isa_ok bif(qw/sync -m m5/),  'Bif::OK::Sync';

    $ref1 = bif( qw/sql --noprint/, qq{select hash from projects order by id} );

    ok $ref1->[0][0] eq $ref2->[0][0], "$ref1->[0][0] eq $ref2->[0][0]";

    my $tinfo = bif(qw/new task -m m6 -p todo tasktitle/);
    my $x     = bif( qw/sql --noprint/,
        qq{select uuid from topics where id=$tinfo->{id}} );
    $tinfo->{uuid} = $x->[0][0];
    bif( qw/update/, $tinfo->{id}, qw/-m m7/ );
    isa_ok bif(qw/sync -m m11/),  'Bif::OK::Sync';
    isa_ok bif2(qw/sync -m m12/), 'Bif::OK::Sync';
    $ref2 = bif2( qw/sql --noprint/,
        qq{select 1 from topics where uuid="$tinfo->{uuid}"} );
    ok $ref2->[0][0], 'task sync';

    my $iinfo = bif2(qw/new issue -m m8 -p todo issuetitle/);
    $x = bif2( qw/sql --noprint/,
        qq{select uuid from topics where id=$iinfo->{id}} );
    $iinfo->{uuid} = $x->[0][0];
    bif2( qw/update/, $iinfo->{id}, qw/-m m10/ );
    isa_ok bif2(qw/sync -m m12/), 'Bif::OK::Sync';
    isa_ok bif(qw/sync -m m13/),  'Bif::OK::Sync';
    $ref1 = bif( qw/sql --noprint/,
        qq{select 1 from topics where uuid="$iinfo->{uuid}"} );
    ok $ref1->[0][0], 'issue sync';

    $ref1 = bif( qw/sql --noprint/, qq{select hash from projects order by id} );
    $ref2 =
      bif2( qw/sql --noprint/, qq{select hash from projects order by id} );

    ok $ref1->[0][0] eq $ref2->[0][0], "$ref1->[0][0] eq $ref2->[0][0]";
};

done_testing();
