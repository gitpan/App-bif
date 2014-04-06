use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);
    my $list = bif(qw/list topics/);
    isa_ok $list, 'Bif::OK::ListTopics';

    # TODO return the id
    bif(qw/ new project todo --message message title /);
    bif(qw/ new task todo --message message task title /);

    # all status
    $list = bif(qw/list topics/);
    isa_ok $list, 'Bif::OK::ListTopics';

    bif(qw/ new task todo --message message task title2 -s stalled/);

    $list = bif(qw/list topics/);
    isa_ok $list, 'Bif::OK::ListTopics';

    $list = bif(qw/list topics --status open/);
    isa_ok $list, 'Bif::OK::ListTopics';

};

done_testing();
