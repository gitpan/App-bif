use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update hub/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/update hub myhub/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init hub myhub/);
    bif(qw/init/);
    bif(qw/pull hub myhub/);

    isa_ok exception { bif(qw/update hub junk/) }, 'Bif::Error::HubNotFound';

    my $u = bif(qw/update hub myhub -m m1/);

    isa_ok $u, 'Bif::OK::ChangeHub';
};

done_testing();
