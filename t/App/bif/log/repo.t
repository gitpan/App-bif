use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log repo junk/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ log repo/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok bif(qw/log repo /), 'Bif::OK::LogRepoTime';

};

done_testing();
