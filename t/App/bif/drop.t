use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    my ( $db, $res, $p, $t, $i, $count, $update );

    $db = bif(qw/init/);
    isa_ok exception { bif(qw/drop unknown /) }, 'Bif::Error::TopicNotFound';

    $p = bif(qw/new project todo --message message title /);

    subtest 'tasks', sub {

        $t = bif(qw/new task todo --message message title /);
        $update = bif( qw/update/, $t->{id}, qw/--message message / );

        $res = bif( qw/drop --force/, $t->{id} . '.' . $update->{update_id} );
        isa_ok $res, 'Bif::OK::DropTaskUpdate';

        $res = bif( qw/drop --force/, $t->{id} );
        isa_ok $res, 'Bif::OK::DropTask';

        isa_ok exception { bif( qw/show/, $t->{id} ) },
          'Bif::Error::TopicNotFound';
    };

    subtest 'issues', sub {

        $i = bif(qw/new issue todo --message message title /);
        $update = bif( qw/update/, $i->{id}, qw/--message message / );

        $res =
          bif( qw/drop --force/, $i->{id} . '.' . $update->{update_id} );
        isa_ok $res, 'Bif::OK::DropIssueUpdate';

        $res = bif( qw/drop --force/, $i->{id} );
        isa_ok $res, 'Bif::OK::DropIssue';

        isa_ok exception { bif( qw/show/, $i->{id} ) },
          'Bif::Error::TopicNotFound';
    };

    subtest 'projects', sub {
        $update = bif( qw/update -m message2/, $p->{id} );

        isa_ok bif( qw/drop /, $p->{id} . '.' . $update->{update_id} ),
          'Bif::OK::DropNoForce';

        $res = bif( qw/drop --force/, $p->{id} . '.' . $update->{update_id} );
        isa_ok $res, 'Bif::OK::DropProjectUpdate';

        $t = bif(qw/new task todo --message message2 title2 /);
        bif( qw/update/, $t->{id}, qw/--message message / );
        $i = bif(qw/new issue todo --message message3 title3 /);
        bif( qw/update/, $i->{id}, qw/--message message / );

        isa_ok bif(qw/drop todo/), 'Bif::OK::DropNoForce';

        $res = bif(qw/drop --force todo/);
        isa_ok $res, 'Bif::OK::DropProject';

        isa_ok exception { bif(qw/show todo/) }, 'Bif::Error::TopicNotFound';

        isa_ok exception { bif( qw/show/, $t->{id} ) },
          'Bif::Error::TopicNotFound';

        isa_ok exception { bif( qw/show/, $i->{id} ) },
          'Bif::Error::TopicNotFound';

        isa_ok exception { bif( qw/show/, $i->{id} ) },
          'Bif::Error::TopicNotFound';
    };

};

done_testing();
