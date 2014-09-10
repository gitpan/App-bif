use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/list entities/) }, 'Bif::Error::RepoNotFound';

    bif(qw/ init /);

    my $list = bif(qw/list entities/);
    isa_ok $list, 'Bif::OK::ListEntities';
};

done_testing();
