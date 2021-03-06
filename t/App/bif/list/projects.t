use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);

    my $list = bif(qw/list projects/);
    isa_ok $list, 'Bif::OK::ListProjects';

    # TODO return the id
    isa_ok bif(qw/ new project todo --message m1 title /),
      'Bif::OK::NewProject';

    isa_ok exception { bif(qw/ list projects junkstatus /) },
      'Bif::Error::InvalidStatus';

    isa_ok bif(qw/ new project todo2 --message m2 title2 --status eval/),
      'Bif::OK::NewProject';

    $list = bif(qw/list projects /);
    isa_ok $list, 'Bif::OK::ListProjects';

    $list = bif(qw/list projects run/);
    isa_ok $list, 'Bif::OK::ListProjects';

};

done_testing();
