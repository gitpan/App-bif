use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ show task /) }, qr/usage:/, 'usage';

    isa_ok exception { bif(qw/ show task 1/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show task 101 /) }, 'Bif::Error::TopicNotFound';

    my $p1  = bif(qw/ new project todo title --message m1 /);
    my $t1  = bif(qw/ new task title --message m2 /);
    my $res = bif( qw/show task/, $t1->{id} );
    isa_ok( $res, 'Bif::OK::ShowTask' );
};

done_testing();
