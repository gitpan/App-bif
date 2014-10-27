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
            my $change_id = $db->nextval('changes');
            my $mtime     = time;
            my $mtimetz   = int( Time::Piece->new->tzoffset );

            $db->xdo(
                insert_into => 'changes',
                values      => {
                    id      => $change_id,
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
                    change_id => $change_id,
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
                    qw/change_id project_id status status rank/
                ],
                select => [ qv($change_id), qv($id), qw/status status rank/, ],
                from   => 'default_status',
                where    => { kind => 'project' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_task_status',
                    qw/change_id project_id status status rank def/
                ],
                select =>
                  [ qv($change_id), qv($id), qw/status status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'task' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_issue_status',
                    qw/change_id project_id status status rank def/
                ],
                select =>
                  [ qv($change_id), qv($id), qw/status status rank def/, ],
                from     => 'default_status',
                where    => { kind => 'issue' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_update_project',
                    qw/change_id id name title status_id/,
                ],
                select =>
                  [ qv($change_id), qv($id), qv('x'), qv('title'), 'id', ],
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
                update => 'changes_pending',
                set    => 'resolve = 1',
            );

            my ($hash2) = $db->selectrow_array(
                q{
            SELECT
                sha1_hex(
                    'change',
                    changes.author,
                    changes.email,
                    changes.lang,
                    changes.message,
                    changes.mtime,
                    changes.mtimetz,
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
                changes
            LEFT JOIN
                changes AS parent
            ON
                parent.id = changes.parent_id
            LEFT JOIN
                project_deltas
            ON
                project_deltas.change_id = changes.id
            LEFT JOIN
                topics AS projects
            ON
                projects.id = project_deltas.project_id
            LEFT JOIN
                topics AS pus -- project_delta_status
            ON
                pus.id = project_deltas.project_status_id
            LEFT JOIN
                project_status_deltas AS psu
            ON
                psu.change_id = changes.id
            LEFT JOIN
                topics AS ps -- project_status
            ON
                ps.id = psu.project_status_id
            WHERE
                changes.id = ?
            }, undef, $change_id
            );

          TODO: {
                local $TODO = 'hash definition still changing';
                is_deeply $db->selectrow_arrayref(
                    'select uuid from changes where id=?',
                    undef, $change_id ),
                  [$hash2], 'change sha match';
            }

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            is_deeply $db->selectrow_arrayref(
                'select project_status.status
                from projects
                inner join project_status
                on projects.project_status_id = project_status.id
                where projects.id=?',
                undef, $id
              ),
              ['run'], 'merge_pending_changes';

            return;

            is_deeply $db->selectrow_arrayref(
                'select uuid from changes where id=?',
                undef, $change_id ),
              [$sha1_hex], 'change sha match';

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
                undef, $change_id
              ),
              [ $id, 'x' ], 'project_deltas';

            eval {
                $db->txn(
                    sub {
                        $db->xdo(
                            insert_into => 'func_new_project',
                            values      => {
                                change_id => $change_id,
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
            my $child_change_id = $db->nextval('changes');

            ok $db->xdo(
                insert_into => 'func_new_project',
                values      => {
                    id        => $child_id,
                    change_id => $child_change_id,
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
                undef, $child_change_id
              ),
              [ $child_id, $id, 'y' ], 'project_deltas';

            $child_change_id = $db->nextval('changes');
            ok $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $child_id,
                    change_id => $child_change_id,
                    author    => 'y',
                    email     => 'y',
                    parent_id => undef,
                    name      => 'z',
                    title     => 'newtitle',
                },
              ),
              'change project';

          TODO: {
                local $TODO = 'can not handle NULL parent_id changes yet';

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
                undef, $child_change_id
              ),
              [ $child_id, undef, 'z' ], 'project_deltas';

            $child_change_id = $db->nextval('changes');

            my $status_id = $db->xval(
                select => 'id',
                from   => 'project_status',
                where  => {
                    project_id => $child_id,
                    status     => 'plan',
                },
            );

            $child_change_id = $db->nextval('changes');

            ok $db->xdo(
                insert_into => 'func_update_project',
                values      => {
                    id        => $child_id,
                    change_id => $child_change_id,
                    mtime     => $mtime + 4,
                    author    => 'y',
                    email     => 'y',
                    status_id => $status_id,
                },
              ),
              'change project status';

            is_deeply $db->selectrow_arrayref(
                'select
                     projects.project_status_id,
                     project_deltas.project_status_id
                 from project_deltas
                 inner join projects
                 on projects.id = project_deltas.project_id
                 where project_deltas.id=?',
                undef, $child_change_id
              ),
              [ $status_id, $status_id ], 'project_deltas';
        }
    );
};

done_testing();
