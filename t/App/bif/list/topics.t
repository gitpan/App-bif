use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);
    is_deeply bif(qw/list topics/), [], 'NoEntries';

    # TODO return the id
    bif(qw/ new project todo --message message title /);
    bif(qw/ new task todo --message message task title /);

    # all status
    my $list = bif(qw/list topics/);

    isa_ok $list, 'Bif::OK::ListTopics';
    is $list->[0][1], 'todo', 'list topics project name';
    is $list->[0][2], 1,      'list topics project count';

    bif(qw/ new task todo --message message task title2 -s stalled/);

    $list = bif(qw/list topics/);
    is $list->[0][2], 2, 'list topics project count';

    $list = bif(qw/list topics --status open/);
    is $list->[0][2], 1, 'list topics project count';

};

done_testing();
