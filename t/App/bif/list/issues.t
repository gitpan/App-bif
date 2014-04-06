use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);
    my $list = bif(qw/list issues/);
    isa_ok $list, 'Bif::OK::ListIssues';

    # TODO return the id
    bif(qw/ new project todo --message message title /);
    bif(qw/ new issue todo --message message issue title /);

    # all status
    $list = bif(qw/list issues/);
    isa_ok $list, 'Bif::OK::ListIssues';

    bif(qw/ new issue todo --message message issue title2 -s stalled/);

    $list = bif(qw/list issues/);
    isa_ok $list, 'Bif::OK::ListIssues';

    $list = bif(qw/list issues --status open/);
    isa_ok $list, 'Bif::OK::ListIssues';

};

done_testing();
