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

run_in_tempdir {

    like exception { bif(qw/export/) }, qr/usage:/, 'usage no args';

    like exception { bif(qw/export todo /) }, qr/usage:/, 'usage one arg';

    isa_ok exception { bif(qw/export todo hub/) },
      'Bif::Error::RepoNotFound', 'repo not found';

    bif(qw/init/);
    isa_ok exception { bif(qw/export todo hub/) },
      'Bif::Error::ProjectNotFound', 'project not found';

    my $pinfo = bif(qw/new project todo title -m message/);
    bif(qw/update todo -m m2/);

    my $tinfo = bif(qw/new task -m message -p todo tasktitle/);
    bif( qw/update/, $tinfo->{id}, qw/-m m2/ );

    my $iinfo = bif(qw/new issue -m message -p todo issuetitle/);

    bif( qw/update/, $iinfo->{id}, qw/-m m2/ );

    isa_ok exception { bif(qw/export todo hub/) },
      'Bif::Error::HubNotFound', 'hub not found';

    bif(qw/init hub/);

    hub(qw/new project todo title2 -m message2/);
    isa_ok exception { bif(qw/export todo hub/) }, 'Bif::Error::PathExists';

    hub(qw/drop --force todo/);
    isa_ok bif(qw/export todo hub/), 'Bif::OK::Created';

    my $here  = bif(qw/show todo/);
    my $there = hub(qw/show todo/);
    isa_ok $there, 'Bif::OK::ShowProject';
    is_deeply $here, $there, 'bif/hub match';

    isa_ok bif(qw/export todo hub/), 'Bif::OK::Found';

    return;

  TODO: {
        local $TODO = 'not implemented yet';

        my $tinfo = bif(qw/new task todo task_title -m message/);

        isa_ok exception { bif( qw/export/, $tinfo->{id}, qw/hub/ ) },
          'Bif::Error::NotAProject', 'not a project';

        bif(qw/init hub/);

        chdir 'hub';
        my $hubdb = App::bif::Util::bif_db();
        bif(qw/new project todo title -m message/);
        chdir '..';

        isa_ok exception { bif(qw/export todo hub/) },
          'Bif::Error::ProjectExists';

        chdir 'hub';
        bif(qw/drop --force todo/);
        chdir '..';

        my $res = bif(qw/export todo hub/);
        is $res, 'BifExport', 'export';

        is_deeply $hubdb->xarray(
            select => 'path',
            from   => 'projects',
            where  => { path => 'todo' },
          ),
          ['path'], 'hub has project';
    }
};

done_testing();
