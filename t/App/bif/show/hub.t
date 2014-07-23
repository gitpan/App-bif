use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ show hub /) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/ show hub local/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show hub unknown /) }, 'Bif::Error::HubNotFound';

    my $x = bif( qw/sql --noprint/, 'select name from hubs' );
    isa_ok bif( qw/ show hub/, $x->[0][0] ), 'Bif::OK::ShowHub';

};

done_testing();
