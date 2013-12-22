use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    bif(qw/ init /);

    is_deeply bif(qw/list projects/), [], 'NoEntries';

    # TODO return the id
    isa_ok bif(qw/ new project todo --message message title /),
      'Bif::OK::NewProject';

    isa_ok exception { bif(qw/ list projects --status junkstatus /) },
      'Bif::Error::InvalidStatus';

    isa_ok bif(qw/ new project todo2 --message message title2 --status eval/),
      'Bif::OK::NewProject';

    is_deeply bif(qw/list projects /),
      [
        [ 'todo',  'title',  'run',  '-', '-', '0%' ],
        [ 'todo2', 'title2', 'eval', '-', '-', '0%' ],
      ],
      'ListAllProjects';

    is_deeply bif(qw/list projects --status run/),
      [ [ 'todo', 'title', 'run', '-', '-', '0%' ] ], 'ListProjects';

};

done_testing();
