use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Test::Bif;
use Test::More;

run_in_tempdir {

    my $db  = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');
    my $xdb = Bif::DBW->connect('dbi:SQLite:dbname=xdb.sqlite3');

    my $update;
    my $project;
    my $project_status;

    $xdb->txn(
        sub {

            $db->deploy;
            $xdb->deploy;

            $update         = new_test_update($xdb);
            $project        = new_test_project($xdb);
            $project_status = new_test_project_status( $xdb, $project );

            $xdb->xdo(
                insert_into => 'func_update_project',
                values      => {
                    update_id => $update->{id},
                    id        => $project->{id},
                    status_id => $project_status->{id}
                },
            );

            $xdb->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    my $res = undef;

    eval {
        $db->txn(
            sub {

                $db->xdo(
                    insert_into => 'func_import_update',
                    values      => $xdb->xhash(
                        select => [
                            'updates.uuid',  'updates.author',
                            'updates.email', 'updates.lang',
                            'updates.mtime', 'updates.mtimetz',
                            'updates.message',
                        ],
                        from  => 'updates',
                        where => { id => $update->{id} },
                    ),
                );

                $db->xdo(
                    insert_into => 'func_import_project',
                    values      => $xdb->xhash(
                        select => [
                            'u.uuid AS update_uuid',
                            'project_deltas.name AS name',
                            'project_deltas.title AS title',
                        ],
                        from       => 'project_deltas',
                        inner_join => 'updates u',
                        on         => 'u.id = project_deltas.update_id',
                        where =>
                          { 'project_deltas.project_id' => $project->{id} },
                        order_by => 'project_deltas.id ASC',
                        limit    => 1,
                    ),
                );

                $db->xdo(
                    insert_into => 'func_import_project_status',
                    values      => $xdb->xhash(
                        select => [
                            'u.uuid AS update_uuid',
                            'project_status_deltas.status AS status',
                            'project_status_deltas.rank AS rank',
                            'topics.uuid AS project_uuid',
                        ],
                        from       => 'project_status_deltas',
                        inner_join => 'updates u',
                        on         => 'u.id = project_status_deltas.update_id',
                        inner_join => 'project_status',
                        on         => {
                            'project_status.id' => \
                              'project_status_deltas.project_status_id',
                        },
                        inner_join => 'topics',
                        on         => 'topics.id = project_status.project_id',
                        where      => {
                            'project_status_deltas.project_status_id' =>
                              $project_status->{id}
                        },
                    ),
                );

                $db->xdo(
                    insert_into => 'func_import_project_delta',
                    values      => $xdb->xhash(
                        select => [
                            'u.uuid AS update_uuid',
                            'projects.uuid AS project_uuid',
                            'status.uuid AS status_uuid',
                        ],
                        from       => 'project_deltas',
                        inner_join => 'updates u',
                        on         => 'u.id = project_deltas.update_id',
                        inner_join => 'topics AS projects',
                        on         => 'projects.id = project_deltas.project_id',
                        inner_join => 'topics AS status',
                        on         => 'status.id = project_deltas.status_id',
                        where =>
                          { 'project_deltas.project_id' => $project->{id} },
                        order_by => 'project_deltas.id DESC',
                        limit    => 1,
                    ),
                );

                $db->xdo(
                    insert_into => 'func_merge_updates',
                    values      => { merge => 1 },
                );

                my $u1 = $xdb->xhashes(
                    select => '*',
                    from   => 'updates',
                );
                my $u2 = $db->xhashes(
                    select => '*',
                    from   => 'updates',
                );

                delete $_->{itime} for @$u1;
                delete $_->{itime} for @$u2;
                is_deeply $u1, $u2, 'updates match';

                $u1 = $xdb->xhashes(
                    select => '*',
                    from   => 'projects',
                );
                $u2 = $db->xhashes(
                    select => '*',
                    from   => 'projects',
                );

                delete $_->{local} for @$u1;
                delete $_->{local} for @$u2;
                delete $_->{itime} for @$u1;
                delete $_->{itime} for @$u2;
                is_deeply $u1, $u2, 'projects match';

                $u1 = $xdb->xhashes(
                    select => '*',
                    from   => 'project_related_updates_merkle',
                );
                $u2 = $db->xhashes(
                    select => '*',
                    from   => 'project_related_updates_merkle',
                );

                is_deeply $u1, $u2, 'project_related_updates_merkle match';
                $res = 1;
            }
        );
    };

    diag($@) unless $res;

    ok $res, 'tests inside txn ok';

};

done_testing();
