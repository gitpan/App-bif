use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ show issue /) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/ show issue 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show issue 101 /) }, 'Bif::Error::TopicNotFound';

    my $p1  = bif(qw/ new project todo title --message m1 /);
    my $t1  = bif(qw/ new issue title --message m2 /);
    my $res = bif( qw/show issue/, $t1->{id} );
    isa_ok( $res, 'Bif::OK::ShowIssue' );
};

done_testing();
