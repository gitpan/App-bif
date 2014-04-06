use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/ show /) }, qr/usage:/, 'usage';
    isa_ok bif(qw/ show VERSION/), 'Bif::OK::ShowVersion';

    isa_ok exception { bif(qw/ show todo/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/ show todo /) }, 'Bif::Error::TopicNotFound';

    my $p1 = bif(qw/ new project todo --message message title /);

    # ID 7 should be somehting like project_status
    isa_ok exception { bif(qw/ show 7 /) }, 'Bif::Error::ShowUnimplemented';

    my $show = bif(qw/show todo/);
    isa_ok( $show, 'Bif::OK::ShowProject' );

    my $t1 = bif(qw/ new task todo --message message task title /);
    $show = bif( qw/show /, $t1->{id} );
    isa_ok( $show, 'Bif::OK::ShowTask' );

    my $i1 = bif(qw/ new issue todo --message message issue title /);
    $show = bif( qw/show /, $i1->{id} );
    isa_ok( $show, 'Bif::OK::ShowIssue' );

    my $update = bif(qw/update todo -m junk/);

    isa_ok exception {
        bif( qw/ show /, "$update->{id}.$update->{update_id}" );
    }, 'Bif::Error::TopicNotFound';
};

done_testing();
