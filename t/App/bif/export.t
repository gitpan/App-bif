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

    isa_ok exception { bif(qw/export/) },          'OptArgs::Usage';
    isa_ok exception { bif(qw/export todo/) },     'OptArgs::Usage';
    isa_ok exception { bif(qw/export todo hub/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/export todo hub/) },
      'Bif::Error::ProjectNotFound';
    my $pinfo = bif(qw/new project todo title -m message/);
    bif(qw/update todo -m m2/);

    #    my $tinfo = bif(qw/new task -m message -p todo tasktitle/);
    #    bif( qw/update/, $tinfo->{id}, qw/-m m2/ );

    #    my $iinfo = bif(qw/new issue -m message -p todo issuetitle/);
    #    bif( qw/update/, $iinfo->{id}, qw/-m m2/ );

    #    isa_ok exception { bif( qw/export/, $tinfo->{id}, qw/hub/ ) },
    #      'Bif::Error::ProjectNotFound';;

    isa_ok exception { bif(qw/export todo hub/) }, 'Bif::Error::HubNotFound';

    bif(qw/init hub --bare/);
    bif(qw/init bif2/);
    bif2(qw/new project todo title2 -m message2/);
    bif2( qw/register/, '../hub' );

    isa_ok bif2(qw/export todo hub -m m4/), 'Bif::OK::Export';
    sleep 1;    # to make repo update uuid different TODO: fix this somehow
    isa_ok bif2(qw/export todo hub -m m5/), 'Bif::OK::Export';

    bif(qw/register hub/);
    isa_ok exception { bif(qw/export todo hub/) }, 'Bif::Error::PathExists';

};

done_testing();
