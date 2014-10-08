use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update plan/) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/update plan p/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/update plan p --message m/) },
      'Bif::Error::TopicNotFound';

    my $pr = bif(qw/ new provider pr email address/);
    my $h  = bif(qw/ new host h/);
    my $p  = bif(qw/ new plan p title/);

    isa_ok bif( qw/update plan/, $p->{id}, qw/-m m1/ ), 'Bif::OK::ChangePlan';

    isa_ok exception {
        bif( qw/update plan/, $p->{id}, '--add', -$h->{id}, qw/-m m2/ );
    }, 'Bif::Error::HostNotFound';

    isa_ok bif( qw/update plan/, $p->{id}, '--add', $h->{id}, qw/-m m2/ ),
      'Bif::OK::ChangePlan';

    isa_ok exception {
        bif( qw/update plan/, $p->{id}, '--remove', -$h->{id}, qw/-m m3/ );
    }, 'Bif::Error::HostNotFound';

    isa_ok bif( qw/update plan/, $p->{id}, '--remove', $h->{id}, qw/-m m3/ ),
      'Bif::OK::ChangePlan';
};

done_testing();
