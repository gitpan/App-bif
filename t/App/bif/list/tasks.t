use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);
    my $list = bif(qw/list tasks/);
    isa_ok $list, 'Bif::OK::ListTasks';

    # TODO return the id
    bif(qw/ new project todo --message m1 title /);
    bif(qw/ new task todo --message m2 task title /);

    # all status
    $list = bif(qw/list tasks/);
    isa_ok $list, 'Bif::OK::ListTasks';

    bif(qw/ new task todo --message m3 task title2 -s stalled/);

    $list = bif(qw/list tasks/);
    isa_ok $list, 'Bif::OK::ListTasks';

    $list = bif(qw/list tasks --status open/);
    isa_ok $list, 'Bif::OK::ListTasks';

};

done_testing();
