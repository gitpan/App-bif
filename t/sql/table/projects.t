use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Digest::SHA qw/sha1_hex/;
use Test::Bif;
use Test::Fatal;
use Test::More skip_all => 'broken by identity changes';
use Time::Piece;

run_in_tempdir {

    DBIx::ThinSQL->import(qw/ qv /);

    my $db = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    $db->txn(
        sub {
            $db->deploy;

            my $id        = $db->nextval('topics');
            my $update_id = $db->nextval('updates');
            my $mtime     = time;
            my $mtimetz   = int( Time::Piece->new->tzoffset );

            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id      => $update_id,
                    mtime   => $mtime,
                    mtimetz => $mtimetz,
                    author  => 'author',
                    email   => 'email',
                    lang    => 'en',
                    message => 'message'
                },
            );

            $db->xdo(
                insert_into => 'func_new_project',
                values      => {
                    id        => $id,
                    update_id => $update_id,
                    name      => 'name',
                    title     => 'title',
                }
            );

            my $sha1_hex = sha1_hex(
                'project', 'author', 'email', 'en', 'message', $mtime,
                $mtimetz,  'name',   'title',
            );

            is_deeply $db->selectrow_arrayref(
                'select topics.uuid,projects.title
                from topics
                inner join projects
                on projects.id = topics.id
                where topics.id=?',
                undef, $id
              ),
              [ $sha1_hex, 'title' ], 'sha match';

            $db->xdo(
                insert_into => [
                    'func_new_project_status',
                    qw/update_id project_id status status rank/
                ],
                select => [ qv($update_id), qv($id), qw/status status rank/, ],
                from   => 'default_status',
                where    => { kind => 'project' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_task_status',
                    qw/update_id project_id status status rank def/
                ],
                select =>
                  [ qv($update_id), qv($id), qw/status status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'task' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_issue_status',
                    qw/update_id project_id status status rank def/
                ],
                select =>
                  [ qv($update_id), qv($id), qw/status status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'issue' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_update_project',
                    qw/update_id id name title status_id/,
                ],
                select =>
                  [ qv($update_id), qv($id), qv('x'), qv('title'), 'id', ],
                from       => 'default_status',
                inner_join => 'project_status',
                on         => {
                    project_id              => $id,
                    'default_status.status' => \'project_status.status',
                },
                where => {
                    'default_status.kind' => 'project',
                    'default_status.def'  => 1,
                },
            );

            $db->xdo(
                update => 'updates_pending',
                set    => 'resolve = 1',
            );

            my ($hash2) = $db->selectrow_array(
                q{
            SELECT
                sha1_hex(
                    'update',
                    updates.author,
                    updates.email,
                    updates.lang,
                    updates.message,
                    updates.mtime,
                    updates.mtimetz,
                    GROUP_CONCAT(project_deltas.name,''),
                    GROUP_CONCAT(project_deltas.title,''),
                    GROUP_CONCAT(psu.status,''),
                    GROUP_CONCAT(psu.status,''),
                    GROUP_CONCAT(psu.rank,''),
                    parent.uuid,
                    GROUP_CONCAT(projects.uuid,''),
                    GROUP_CONCAT(ps.uuid,''),
                    GROUP_CONCAT(pus.uuid,'')
                )
            FROM
                updates
            LEFT JOIN
                updates AS parent
            ON
                parent.id = updates.parent_id
            LEFT JOIN
                project_deltas
            ON
                project_deltas.update_id = updates.id
            LEFT JOIN
                topics AS projects
            ON
                projects.id = project_deltas.project_id
            LEFT JOIN
                topics AS pus -- project_delta_status
            ON
                pus.id = project_deltas.status_id
            LEFT JOIN
                project_status_deltas AS psu
            ON
                psu.update_id = updates.id
            LEFT JOIN
                topics AS ps -- project_status
            ON
                ps.id = psu.project_status_id
            WHERE
                updates.id = ?
            }, undef, $update_id
            );

          TODO: {
                local $TODO = 'hash definition still changing';
                is_deeply $db->selectrow_arrayref(
                    'select uuid from updates where id=?',
                    undef, $update_id ),
                  [$hash2], 'update sha match';
            }

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            is_deeply $db->selectrow_arrayref(
                'select project_status.status
                from projects
                inner join project_status
                on projects.status_id = project_status.id
                where projects.id=?',
                undef, $id
              ),
              ['run'], 'merge_pending_updates';

            return;

            is_deeply $db->selectrow_arrayref(
                'select uuid from updates where id=?',
                undef, $update_id ),
              [$sha1_hex], 'update sha match';

            is_deeply $db->selectrow_arrayref(
                'select name,path from projects
                 where id=?',
                undef, $id
              ),
              [ 'x', 'x' ], 'projects';

            is_deeply $db->selectrow_arrayref(
                'select project_id,name
                 from project_deltas
                 where id=?',
                undef, $update_id
              ),
              [ $id, 'x' ], 'project_deltas';

            eval {
                $db->txn(
                    sub {
                        $db->xdo(
                            insert_into => 'func_new_project',
                            values      => {
                                update_id => $update_id,
                                author    => 'x',
                                email     => 'x',
                                name      => 'x2',
                            },
                        );
                    }
                );
            };

            like $@, qr/not unique/, 'insert duplicate name';
            my $child_id        = $db->nextval('topics');
            my $child_update_id = $db->nextval('updates');

            ok $db->xdo(
                insert_into => 'func_new_project',
                values      => {
                    id        => $child_id,
                    update_id => $child_update_id,
                    author    => 'y',
                    email     => 'y',
                    parent_id => $id,
                    name      => 'y',
                },
              ),
              'insert child project';

            is_deeply $db->selectrow_arrayref(
                'select name,path from projects
                 where id=?',
                undef, $child_id
              ),
              [ 'y', 'x/y' ], 'projects';

            is_deeply $db->selectrow_arrayref(
                'select project_id,parent_id,name
                 from project_deltas
                 where id=?',
                undef, $child_update_id
              ),
              [ $child_id, $id, 'y' ], 'project_deltas';

            $child_update_id = $db->nextval('updates');
            ok $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $child_id,
                    update_id => $child_update_id,
                    author    => 'y',
                    email     => 'y',
                    parent_id => undef,
                    name      => 'z',
                    title     => 'newtitle',
                },
              ),
              'update project';

          TODO: {
                local $TODO = 'can not handle NULL parent_id updates yet';

                is_deeply $db->selectrow_arrayref(
                    'select name,path,title
                    from projects
                    inner join topics on
                    projects.id = topics.id
                 where projects.id=?',
                    undef, $child_id
                  ),
                  [ 'z', 'z', 'newtitle' ], 'projects';
            }

            is_deeply $db->selectrow_arrayref(
                'select project_id,parent_id,name
                 from project_deltas
                 where id=?',
                undef, $child_update_id
              ),
              [ $child_id, undef, 'z' ], 'project_deltas';

            $child_update_id = $db->nextval('updates');

            my ($status_id) = $db->xarray(
                select => 'id',
                from   => 'project_status',
                where  => {
                    project_id => $child_id,
                    status     => 'plan',
                },
            );

            $child_update_id = $db->nextval('updates');

            ok $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $child_id,
                    update_id => $child_update_id,
                    mtime     => $mtime + 4,
                    author    => 'y',
                    email     => 'y',
                    status_id => $status_id,
                },
              ),
              'update project status';

            is_deeply $db->selectrow_arrayref(
                'select
                     projects.status_id,
                     project_deltas.status_id
                 from project_deltas
                 inner join projects
                 on projects.id = project_deltas.project_id
                 where project_deltas.id=?',
                undef, $child_update_id
              ),
              [ $status_id, $status_id ], 'project_deltas';
        }
    );
};

done_testing();
