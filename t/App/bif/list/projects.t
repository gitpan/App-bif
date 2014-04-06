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
    isa_ok bif(qw/ new project todo --message message title /),
      'Bif::OK::NewProject';

    isa_ok exception { bif(qw/ list projects --status junkstatus /) },
      'Bif::Error::InvalidStatus';

    isa_ok bif(qw/ new project todo2 --message message title2 --status eval/),
      'Bif::OK::NewProject';

    $list = bif(qw/list projects /);
    isa_ok $list, 'Bif::OK::ListProjects';

    $list = bif(qw/list projects --status run/);
    isa_ok $list, 'Bif::OK::ListProjects';

};

done_testing();
