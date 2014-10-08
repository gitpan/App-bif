use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use Test::Bif;
use Test::Fatal;
use Test::More;

my $have_version = path(qw/lib App bif Build/)->exists;

run_in_tempdir {

    like exception { bif(qw/ show /) }, qr/usage:/, 'usage';
    isa_ok bif(qw/ show VERSION/), 'Bif::OK::ShowVersion'
      if $have_version;

    isa_ok exception { bif(qw/ show todo/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show todo /) }, 'Bif::Error::TopicNotFound';

    my $p1 = bif(qw/ new project todo --message m1 title /);

    my $show = bif(qw/show todo/);
    isa_ok( $show, 'Bif::OK::ShowProject' );

    my $t1 = bif(qw/ new task todo --message m2 task title /);
    $show = bif( qw/show /, $t1->{id} );
    isa_ok( $show, 'Bif::OK::ShowTask' );

    my $i1 = bif(qw/ new issue todo --message m3 issue title /);
    $show = bif( qw/show /, $i1->{id} );
    isa_ok( $show, 'Bif::OK::ShowIssue' );

    my $change = bif(qw/update todo -m m4/);

    isa_ok exception {
        bif( qw/ show /, "$change->{id}.$change->{change_id}" );
    }, 'Bif::Error::TopicNotFound';
};

done_testing();
