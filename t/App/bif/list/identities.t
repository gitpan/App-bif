use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/list identities/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/ init /);

    my $list = bif(qw/list identities/);
    isa_ok $list, 'Bif::OK::ListIdentities';
};

done_testing();
