use strict;
use warnings;
use lib 't/lib';
use Bif::DB::RW;
use Test::Bif;
use Test::More;

run_in_tempdir {

    my $db = Bif::DB::RW->connect('dbi:SQLite:dbname=db.sqlite3');

    my $res = undef;
    eval {
        $db->txn(
            sub {
                $db->deploy;

                my $update  = new_test_update($db);
                my $project = new_test_project($db);

                my $task_status = {
                    update_id  => $update->{id},
                    id         => $db->nextval('topics'),
                    project_id => $project->{id},
                    status     => 'a_status',
                    rank       => 10,
                };

                ok $db->xdo(
                    insert_into => 'func_new_task_status',
                    values      => $task_status,
                  ),
                  'new_task_status';

                my $row = $db->xarray(
                    select     => 1,
                    from       => 'task_status',
                    inner_join => 'topics',
                    on         => 'topics.id = task_status.id',
                    inner_join => 'projects',
                    on         => 'projects.id = task_status.project_id',
                    where      => {
                        'task_status.id'     => $task_status->{id},
                        'task_status.status' => $task_status->{status},
                        'task_status.rank'   => $task_status->{rank},
                    }
                );

                ok $row, 'func_new_task_status';

                $res = 1;
            }
        );
    };

    diag($@) unless $res;

    ok $res, 'tests inside txn ok';

};

done_testing();