use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

plan skip_all => 'not implemented yet';

run_in_tempdir {

    bif(qw/init/);
    bif(qw/new project todo title -m message/);

    bif(qw/init hub/);
    chdir 'hub';

    like exception { bif(qw/import/) }, qr/usage:/;

    bif(qw/new project todo title -m message/);
    isa_ok exception { bif(qw/import .. todo/) }, 'Bif::Error::ProjectExists';

  TODO: {
        local $TODO = 'not implemented';
        bif(qw/drop --force todo/);

        my $res = bif(qw/import .. todo/);

        is $res, 'BifImport';

        my $db = App::Bif::Util::bif_db();
        is_deeply $db->xarray(
            select => 'path',
            from   => 'projects',
            where  => { path => 'todo' },
          ),
          ['path'], 'import';
    }
};

done_testing();
