use strict;
use warnings;
use lib 't/lib';
use File::chdir;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/push project/) },      'OptArgs::Usage';
    isa_ok exception { bif(qw/push project todo/) }, 'OptArgs::Usage';
    isa_ok exception { bif(qw/push project todo hub/) },
      'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/push project todo hub/) },
      'Bif::Error::ProjectNotFound';

    my $pinfo = bif(qw/new project todo title -m message/);
    bif(qw/update todo -m m2/);

    my $tinfo = bif(qw/new task -m message -p todo tasktitle/);
    bif( qw/update/, $tinfo->{id}, qw/-m m2/ );

    my $iinfo = bif(qw/new issue -m message -p todo issuetitle/);
    bif( qw/update/, $iinfo->{id}, qw/-m m2/ );

    isa_ok exception { bif( qw/push project/, $tinfo->{id}, qw/hub/ ) },
      'Bif::Error::ProjectNotFound';

    isa_ok exception { bif(qw/push project todo hub/) },
      'Bif::Error::HubNotFound';

    bif(qw/init hub hub/);

    bif2(qw/init/);
    bif2(qw/new project todo title2 -m message2/);
    bif2( qw/pull hub/, '../hub' );

    isa_ok bif2(qw/push project todo hub -m m4/), 'Bif::OK::PushProject';

    bif(qw/pull hub hub/);
    isa_ok exception { bif(qw/push project todo hub/) },
      'Bif::Error::PathExists';

};

done_testing();
