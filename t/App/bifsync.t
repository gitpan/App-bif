use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {
    isa_ok exception { bifsync(qw/too many arguments/) }, 'OptArgs::Usage';
    isa_ok exception { bifsync(qw/notfound/) }, 'Bif::Error::RepoNotFound';
};

done_testing();
