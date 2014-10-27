use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ list actions junk/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ list actions/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok bif(qw/list actions /),          'Bif::OK::ListActionsTime';
    isa_ok bif(qw/list actions --action /), 'Bif::OK::ListActionsUid';

};

done_testing();
