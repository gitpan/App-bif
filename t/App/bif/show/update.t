use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ show update /) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/ show update u1/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show update u101 /) },
      'Bif::Error::UpdateNotFound';

    my $res = bif(qw/show update u1/);
    isa_ok( $res, 'Bif::OK::ShowUpdate' );
};

done_testing();
