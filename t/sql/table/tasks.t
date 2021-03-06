use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Digest::SHA qw/sha1_hex/;
use Test::Bif;
use Test::Fatal;
use Test::More;
use Time::Piece;

plan skip_all => 'Need to rework';

run_in_tempdir {

    bif('init');
    my $db = Bif::DBW->connect('dbi:SQLite:dbname=.bif/db.sqlite3');

    my $pid = $db->nextval('topics');
    $db->xdo(
        insert_into => 'func_new_project',
        values      => {
            id      => $pid,
            author  => 'x',
            email   => 'x',
            lang    => 'en',
            title   => 'title',
            message => 'message',
            name    => 'x',
        },
    );

    my $status_id = $db->xval(
        select => 'id',
        from   => 'task_status',
        where  => {
            project_id => $pid,
            def        => 1,
        },
    );
    ok $status_id, 'new project inserted task_status default';

    my $done_status_id = $db->xval(
        select => 'id',
        from   => 'task_status',
        where  => {
            project_id => $pid,
            status     => 'done',
        },
    );
    ok $done_status_id, 'new project inserted task_status done';

    my $id        = $db->nextval('topics');
    my $change_id = $db->nextval('changes');
    my $mtime     = time;
    my $mtimetz   = int( Time::Piece->new->tzoffset );

    ok $db->xdo(
        insert_into => 'func_new_task',
        values      => {
            project_id => $pid,
            id         => $id,
            change_id  => $change_id,
            mtime      => $mtime,
            mtimetz    => $mtimetz,
            author     => 'x',
            email      => 'x',
            lang       => 'en',
            title      => 'title',
            message    => 'message',
        },
      ),
      'insert task';

    my $sha1_hex =
      sha1_hex( 'task', $mtime, $mtimetz, 'x', 'x', 'en', 'title', 'message', );

    is_deeply $db->selectrow_arrayref(
        'select uuid,kind,title from topics where id=?',
        undef, $id ),
      [ $sha1_hex, 'task', 'title' ], 'sha match';

    is_deeply $db->selectrow_arrayref(
        'select uuid,title from changes where id=?',
        undef, $change_id ),
      [ $sha1_hex, 'title' ], 'change sha match';

    is_deeply $db->selectrow_arrayref(
        'select status_id from tasks
                 where id=?',
        undef, $id
      ),
      [$status_id], 'tasks';

    is_deeply $db->selectrow_arrayref(
        'select task_id,status_id
                 from task_deltas
                 where id=?',
        undef, $change_id
      ),
      [ $id, $status_id ], 'task_deltas';

    ok $db->xdo(
        insert_into => 'func_new_task',
        values      => {
            project_id => $pid,
            author     => 'x',
            email      => 'x2',
            lang       => 'en',
            title      => 'title',
            message    => 'message',
        },
      ),
      'insert task no IDs';

    eval {
        $db->txn(
            sub {
                $db->xdo(
                    insert_into => 'func_new_task',
                    values      => {
                        project_id => $pid,
                        mtime      => $mtime,
                        mtimetz    => $mtimetz,
                        author     => 'x',
                        email      => 'x',
                        lang       => 'en',
                        title      => 'title',
                        message    => 'message',
                    },
                );
            }
        );
    };

    like $@, qr/not unique/, 'insert duplicate details';

=cut
    my $child_id        = $db->nextval('topics');
    my $child_change_id = $db->nextval('changes');

    ok $db->xdo(
        insert_into => 'func_new_task',
        values      => {
            project_id => $pid,
            id         => $child_id,
            change_id  => $child_change_id,
            author     => 'y',
            email      => 'y',
            parent_id  => $id,
            lang       => 'en',
            title      => 'title',
            message    => 'message',
        },
      ),
      'insert child task';

    is_deeply $db->selectrow_arrayref(
        'select name,path from projects
                 where id=?',
        undef, $child_id
      ),
      [ 'y', 'x/y' ], 'tasks';

    is_deeply $db->selectrow_arrayref(
        'select project_id,parent_id,name
                 from project_deltas
                 where id=?',
        undef, $child_change_id
      ),
      [ $child_id, $id, 'y' ], 'task_deltas';

=cut

    $change_id = $db->nextval('changes');
    ok $db->xdo(
        insert_into => 'func_update_task',
        values      => {
            id        => $id,
            change_id => $change_id,
            mtime     => $mtime + 3,
            author    => 'y',
            email     => 'y',
            title     => 'newtitle',
        },
      ),
      'change task title';

    is_deeply $db->selectrow_arrayref(
        'select title
         from topics
         where id=?',
        undef, $id
      ),
      ['newtitle'], 'task title change';

    $change_id = $db->nextval('changes');

    ok $db->xdo(
        insert_into => 'func_update_task',
        values      => {
            id        => $id,
            change_id => $change_id,
            mtime     => $mtime + 4,
            author    => 'y',
            email     => 'y',
            status_id => $done_status_id,
        },
      ),
      'change task status';

    is_deeply $db->selectrow_arrayref(
        'select status_id
         from task_deltas
         where id = ?',
        undef, $change_id
      ),
      [$done_status_id], 'task_deltas';
    return;

    is_deeply $db->selectrow_arrayref(
        'select tasks.task_status_id, tasks.change_id
         from tasks
         where tasks.id=?',
        undef, $id
      ),
      [ $done_status_id, $change_id ], 'tasks changed';

    $change_id = $db->nextval('changes');

    ok $db->xdo(
        insert_into => 'func_update_task',
        values      => {
            id        => $id,
            change_id => $change_id,
            mtime     => $mtime + 2,
            author    => 'y',
            email     => 'y',
            status_id => $status_id,
        },
      ),
      'change task status';

    is_deeply $db->selectrow_arrayref(
        'select tasks.task_status_id, task_deltas.task_status_id
         from task_deltas
         inner join tasks
         on tasks.id = task_deltas.task_id
         where task_deltas.id=?',
        undef, $change_id
      ),
      [ $done_status_id, $status_id ], 'out of order task_deltas';

};

done_testing();
