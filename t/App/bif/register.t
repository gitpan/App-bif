use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

sub hub {
    local $CWD = 'hub';
    bif(@_);
}

sub bif2 {
    local $CWD = 'bif2';
    bif(@_);
}

run_in_tempdir {

    isa_ok exception { bif(qw/register/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/register hub/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/register hub/) }, 'Bif::Error::HubNotFound';

    bif(qw/init hub --bare/);
    isa_ok bif(qw/register hub/), 'Bif::OK::Register';

    isa_ok exception { bif(qw/register hub/) }, 'Bif::Error::RepoExists';
};

run_in_tempdir {
    bif(qw/init/);
    bif(qw/init bif2/);
    bif(qw/init hub --bare/);

    my $pinfo = bif2(qw/new project todo title -m message/);
    bif2(qw/update todo -m m2/);

    my $tinfo = bif2(qw/new task -m message -p todo tasktitle/);
    bif2( qw/update/, $tinfo->{id}, qw/-m m2/ );
    my $ref = bif2( qw/sql --noprint/,
        "select uuid from topics where id=$tinfo->{id}" );
    $tinfo->{uuid} = $ref->[0][0];

    $ref = bif2( qw/sql --noprint/,
        "select id from topics where uuid='$tinfo->{uuid}'" );
    is $ref->[0][0], $tinfo->{id}, 'uuid -> id';

    my $iinfo = bif2(qw/new issue -m m3 -p todo issuetitle/);
    bif2( qw/update/, $tinfo->{id}, qw/-m m4/ );
    $ref = bif2( qw/sql --noprint/,
        "select uuid from topics where id=$iinfo->{id}" );
    $iinfo->{uuid} = $ref->[0][0];

    $ref = bif2( qw/sql --noprint/,
        "select id from topics where uuid='$iinfo->{uuid}'" );
    is $ref->[0][0], $iinfo->{id}, 'uuid -> id';

    #    my $iinfo = hub(qw/new issue -m message -p todo issuetitle/);
    #    hub( qw/update/, $iinfo->{id}, qw/-m m2/ );

    isa_ok bif2( qw/register/, '../hub' ), 'Bif::OK::Register';
    bif2(qw/export todo hub/);

    isa_ok bif(qw/register hub/), 'Bif::OK::Register';
    my $list = bif(qw/list hubs/);
    isa_ok $list, 'Bif::OK::ListHubs';    # TODO need to do better than this

    isa_ok exception { bif(qw/show todo/) }, 'Bif::Error::TopicNotFound';

    # TODO   isa_ok bif(qw/show todo hub/), 'Bif::OK::ShowProject';
    isa_ok bif(qw/show todo hub/), 'Bif::OK::ShowProject';

    $ref = bif( qw/sql --noprint/,
        "select id from topics where uuid='$tinfo->{uuid}'" );
    is $ref->[0][0], undef, 'register not include tasks';

    $ref = bif( qw/sql --noprint/,
        "select id from topics where uuid='$iinfo->{uuid}'" );
    is $ref->[0][0], undef, 'register not include issues';

};

done_testing();
