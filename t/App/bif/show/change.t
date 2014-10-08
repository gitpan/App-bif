use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ show change /) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/ show change c1/) },
      'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show change c101 /) },
      'Bif::Error::ChangeNotFound';

    my $res = bif(qw/show change c1/);
    isa_ok( $res, 'Bif::OK::ShowChange' );
};

done_testing();
