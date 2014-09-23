use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/drop project /) },     'OptArgs::Usage';
    isa_ok exception { bif(qw/drop project todo/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    bif(qw/init hub hub/);
    bif(qw/pull hub hub/);

    isa_ok exception { bif(qw/drop project todo/) },
      'Bif::Error::ProjectNotFound';

    bif(qw/new project todo title -m m1/);
    bif(qw/new project todo2 title -m m2/);

    # Create a task
    my $t1 = bif(qw/new task title -p todo -m m3/);
    my $x =
      bif( qw/sql --noprint/, qq{select uuid from topics where id=$t1->{id}} );
    $t1->{uuid} = $x->[0]->[0];

    # Create two issues and push them so that each project has a
    # "created" issue and a "pushed" issue
    my $i1 = bif(qw/new issue title -p todo -m m4/);
    bif( qw/push issue/, $i1->{id}, qw/ todo2 -m m5/ );
    $x = bif( qw/sql --noprint/,
        qq{select uuid from topics where id=$i1->{topic_id}} );
    $i1->{uuid} = $x->[0]->[0];

    my $i2 = bif(qw/new issue title -p todo2 -m m6/);
    bif( qw/push issue/, $i2->{id}, qw/ todo -m m7/ );
    $x = bif( qw/sql --noprint/,
        qq{select uuid from topics where id=$i2->{topic_id}} );
    $i2->{uuid} = $x->[0]->[0];

    # Drop it!
    isa_ok bif(qw/drop project todo/),    'Bif::OK::DropNoForce';
    isa_ok bif(qw/drop project todo -f/), 'Bif::OK::DropProject';
    isa_ok exception { bif(qw/show project todo/) },
      'Bif::Error::ProjectNotFound';

    # tasks need to have gone
    isa_ok exception { bif( qw/show task /, $t1->{id} ) },
      'Bif::Error::TopicNotFound';

    # issues *created* in that project must go
    isa_ok exception { bif( qw/show issue /, $i1->{id} ) },
      'Bif::Error::TopicNotFound';

    # issues *pushed* to that project can stay
    isa_ok bif( qw/show issue /, $i2->{id} ), 'Bif::OK::ShowIssue';

    # Now test effects of dropping a project on *_merkle tables

    bif(qw/new project todo3 title -m m8/);
    bif( qw/push issue/, $i2->{id}, qw/todo3 -m m9/ );

    my $t2 = bif(qw/new task title -p todo2 -m m10/);
    $x =
      bif( qw/sql --noprint/, qq{select uuid from topics where id=$t2->{id}} );
    $t2->{uuid} = $x->[0]->[0];

    my $i3 = bif(qw/new issue title -p todo3 -m m11/);
    bif( qw/push issue/, $i3->{id}, qw/ todo2 -m m12/ );
    $x = bif( qw/sql --noprint/,
        qq{select uuid from topics where id=$i3->{topic_id}} );
    $i3->{uuid} = $x->[0]->[0];

    # a standalone issue
    my $i4 = bif(qw/new issue title -p todo2 -m m13/);
    $x = bif( qw/sql --noprint/,
        qq{select uuid from topics where id=$i4->{topic_id}} );
    $i4->{uuid} = $x->[0]->[0];

    # Send projects to a hub for later tests
    bif(qw/push project todo2 todo3 hub/);

    isa_ok bif(qw/drop project todo2 --force/), 'Bif::OK::DropProjectShallow';

    # In the case of a shallow drop *all* of the issues should still be
    # around, even through the task will have gone
    isa_ok bif( qw/show issue --uuid/, $i2->{uuid} ), 'Bif::OK::ShowIssue';
    isa_ok bif( qw/show issue --uuid/, $i3->{uuid} ), 'Bif::OK::ShowIssue';
    isa_ok exception { bif( qw/show issue /, $i4->{id} ) },
      'Bif::Error::TopicNotFound';
    isa_ok exception { bif( qw/show task /, $t2->{id} ) },
      'Bif::Error::TopicNotFound';

    isa_ok exception { bif( qw/show task --uuid/, $t2->{uuid} ) },
      'Bif::Error::UuidNotFound';

    # This will fail to pull in the task if the drop didn't take care
    # of the related_changes[_merkle] tables
    bif(qw/pull project todo2/);

    # Of course, this also can fail if the pull failed, but we still
    # need to test that drop worked.... I think? It's late and I can't
    # actually think straight. Maybe this is tested in pull project
    # tests. TODO.
    isa_ok bif( qw/show issue --uuid/, $i4->{uuid} ), 'Bif::OK::ShowIssue';
    isa_ok bif( qw/show task --uuid/,  $t2->{uuid} ), 'Bif::OK::ShowTask';
};

done_testing();
