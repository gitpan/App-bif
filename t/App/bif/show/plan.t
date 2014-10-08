use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/show plan/) }, 'OptArgs::Usage';

    isa_ok exception { bif(qw/show plan 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/show plan 111111 /) }, 'Bif::Error::PlanNotFound';

    my $pr = bif(qw/ new provider pr email address/);
    my $p  = bif(qw/ new plan p title/);

    isa_ok bif( qw/show plan/, $p->{id} ), 'Bif::OK::ShowPlan';
};

done_testing();
