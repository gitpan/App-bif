use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Test::Bif;
use Test::More skip_all => 'broken by identity changes';

run_in_tempdir {

    my $db  = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');
    my $xdb = Bif::DBW->connect('dbi:SQLite:dbname=xdb.sqlite3');

    my $change;
    my $project;
    my $project_status;

    $xdb->txn(
        sub {

            $db->deploy;
            $xdb->deploy;

            $change         = new_test_change($xdb);
            $project        = new_test_project($xdb);
            $project_status = new_test_project_status( $xdb, $project );

            $xdb->xdo(
                insert_into => 'func_change_project',
                values      => {
                    change_id => $change->{id},
                    id        => $project->{id},
                    status_id => $project_status->{id}
                },
            );

            $xdb->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

        }
    );

    my $res = undef;

    eval {
        $db->txn(
            sub {

                $db->xdo(
                    insert_into => 'func_import_change',
                    values      => $xdb->xhashref(
                        select => [
                            'changes.uuid',  'changes.author',
                            'changes.email', 'changes.lang',
                            'changes.mtime', 'changes.mtimetz',
                            'changes.message',
                        ],
                        from  => 'changes',
                        where => { id => $change->{id} },
                    ),
                );

                $db->xdo(
                    insert_into => 'func_import_project',
                    values      => $xdb->xhashref(
                        select => [
                            'c.uuid AS change_uuid',
                            'project_deltas.name AS name',
                            'project_deltas.title AS title',
                        ],
                        from       => 'project_deltas',
                        inner_join => 'changes c',
                        on         => 'c.id = project_deltas.change_id',
                        where =>
                          { 'project_deltas.project_id' => $project->{id} },
                        order_by => 'project_deltas.id ASC',
                        limit    => 1,
                    ),
                );

                $db->xdo(
                    insert_into => 'func_import_project_status',
                    values      => $xdb->xhashref(
                        select => [
                            'c.uuid AS change_uuid',
                            'project_status_deltas.status AS status',
                            'project_status_deltas.rank AS rank',
                            'topics.uuid AS project_uuid',
                        ],
                        from       => 'project_status_deltas',
                        inner_join => 'changes c',
                        on         => 'c.id = project_status_deltas.change_id',
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
                    values      => $xdb->xhashref(
                        select => [
                            'c.uuid AS change_uuid',
                            'projects.uuid AS project_uuid',
                            'status.uuid AS status_uuid',
                        ],
                        from       => 'project_deltas',
                        inner_join => 'changes c',
                        on         => 'c.id = project_deltas.change_id',
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
                    insert_into => 'func_merge_changes',
                    values      => { merge => 1 },
                );

                my $c1 = $xdb->xhashrefs(
                    select => '*',
                    from   => 'changes',
                );
                my $c2 = $db->xhashrefs(
                    select => '*',
                    from   => 'changes',
                );

                delete $_->{itime} for @$c1;
                delete $_->{itime} for @$c2;
                is_deeply $c1, $c2, 'changes match';

                $c1 = $xdb->xhashrefs(
                    select => '*',
                    from   => 'projects',
                );
                $c2 = $db->xhashrefs(
                    select => '*',
                    from   => 'projects',
                );

                delete $_->{local} for @$c1;
                delete $_->{local} for @$c2;
                delete $_->{itime} for @$c1;
                delete $_->{itime} for @$c2;
                is_deeply $c1, $c2, 'projects match';

                $c1 = $xdb->xhashrefs(
                    select => '*',
                    from   => 'project_related_changes_merkle',
                );
                $c2 = $db->xhashrefs(
                    select => '*',
                    from   => 'project_related_changes_merkle',
                );

                is_deeply $c1, $c2, 'project_related_changes_merkle match';
                $res = 1;
            }
        );
    };

    diag($@) unless $res;

    ok $res, 'tests inside txn ok';

};

done_testing();
