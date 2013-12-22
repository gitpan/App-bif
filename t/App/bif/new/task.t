use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    my $db = bif(qw/init/);

    isa_ok exception { bif(qw/ new task/) }, 'Bif::Error::TitleRequired';

    isa_ok exception { bif(qw/ new task title/) },
      'Bif::Error::ProjectRequired';

    isa_ok exception { bif(qw/ new task -p todo title/) },
      'Bif::Error::ProjectNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception { bif(qw/ new task -p todo this is the title/) },
      'Bif::Error::EmptyContent';

    my $i = bif(qw/new task -p todo title -m message/);
    ok $i->{id}, 'task created ' . $i->{id};

    is_deeply [
        $db->xarray(
            select     => [qw/task_status.def task_status.project_id/],
            from       => 'tasks',
            inner_join => 'task_status',
            on         => 'task_status.id = tasks.status_id',
            where      => { 'tasks.id' => $i->{id} },
        )
      ],
      [ 1, $p->{id} ], 'task default status and project ok';

    isa_ok exception { bif(qw/ new task -p todo title -s unknown/) },
      'Bif::Error::InvalidStatus';

    my $i2 = bif(qw/new task -p todo title -m message2 -s stalled/);

    is_deeply [
        $db->xarray(
            select     => [qw/task_status.status task_status.project_id/],
            from       => 'tasks',
            inner_join => 'task_status',
            on         => 'task_status.id = tasks.status_id',
            where      => { 'tasks.id' => $i2->{id} },
        )
      ],
      [ 'stalled', $p->{id} ], 'task status and project ok';

};

done_testing();
