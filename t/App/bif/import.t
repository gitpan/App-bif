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

    isa_ok exception { bif(qw/import/) },          'OptArgs::Usage';
    isa_ok exception { bif(qw/import todo/) },     'OptArgs::Usage';
    isa_ok exception { bif(qw/import todo hub/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/import todo hub/) }, 'Bif::Error::HubNotFound';

    bif(qw/init hub --bare/);
    bif(qw/register hub/);
    isa_ok exception { bif(qw/import todo hub/) },
      'Bif::Error::ProjectNotFound';

    bif(qw/new project todo title -m message/);
    my $tinfo = bif(qw/new task -m message -p todo tasktitle/);
    my $ref =
      bif( qw/sql --noprint/, "select uuid from topics where id=$tinfo->{id}" );
    $tinfo->{uuid} = $ref->[0][0];

    bif( qw/update/, $tinfo->{id}, qw/-m m2/ );
    bif(qw/export todo hub -m m3/);

    bif(qw/init bif2/);
    bif2( 'register', '../hub' );
    isa_ok exception { bif2(qw/show todo/) }, 'Bif::Error::TopicNotFound';
    isa_ok bif2(qw/show todo hub/), 'Bif::OK::ShowProject';

    isa_ok exception { bif2( qw/show --uuid/, $tinfo->{uuid} ) },
      'Bif::Error::UuidNotFound';

    #    my $iinfo = bif(qw/new issue -m message -p todo issuetitle/);
    #    bif( qw/update/, $iinfo->{id}, qw/-m m2/ );

    #    isa_ok exception { bif( qw/import/, $tinfo->{id}, qw/hub/ ) },
    #      'Bif::Error::ProjectNotFound';;

    isa_ok bif2(qw/import todo hub/), 'Bif::OK::Import';

    isa_ok bif2(qw/show todo/), 'Bif::OK::ShowProject';
    isa_ok bif2( qw/show --uuid/, $tinfo->{uuid} ), 'Bif::OK::ShowTask';

    isa_ok bif2(qw/import todo hub/), 'Bif::OK::Import';

    return;
};

done_testing();
