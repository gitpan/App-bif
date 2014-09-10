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

    my $db = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    $db->txn(
        sub {
            $db->deploy;

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
                from   => 'issue_status',
                where  => {
                    project_id => $pid,
                    def        => 1,
                },
            );
            ok $status_id, 'new project inserted issue_status default';

            my $needinfo_status_id = $db->xval(
                select => 'id',
                from   => 'issue_status',
                where  => {
                    project_id => $pid,
                    status     => 'needinfo',
                },
            );
            ok $needinfo_status_id,
              'new project inserted issue_status needinfo';

            my $id        = $db->nextval('topics');
            my $update_id = $db->nextval('updates');
            my $mtime     = time;
            my $mtimetz   = int( Time::Piece->new->tzoffset );

            ok $db->xdo(
                insert_into => 'func_new_issue',
                values      => {
                    project_id => $pid,
                    id         => $id,
                    update_id  => $update_id,
                    mtime      => $mtime,
                    mtimetz    => $mtimetz,
                    author     => 'x',
                    email      => 'x',
                    lang       => 'en',
                    title      => 'title',
                    message    => 'message',
                },
              ),
              'insert issue';

            my $sha1_hex =
              sha1_hex( 'issue', $mtime, $mtimetz, 'x', 'x', 'en', 'title',
                'message', );

            is_deeply $db->selectrow_arrayref(
                'select uuid,kind,title from topics where id=?',
                undef, $id ),
              [ $sha1_hex, 'issue', 'title' ], 'sha match';

            is_deeply $db->selectrow_arrayref(
                'select uuid,title from updates where id=?',
                undef, $update_id ),
              [ $sha1_hex, 'title' ], 'update sha match';

            is_deeply $db->selectrow_arrayref(
                'select status_id from project_issues
                 where issue_id=?',
                undef, $id
              ),
              [$status_id], 'issues';

            is_deeply $db->selectrow_arrayref(
                'select issue_id,status_id
                 from issue_deltas
                 where id=?',
                undef, $update_id
              ),
              [ $id, $status_id ], 'issue_deltas';

            ok $db->xdo(
                insert_into => 'func_new_issue',
                values      => {
                    project_id => $pid,
                    author     => 'x',
                    email      => 'x2',
                    lang       => 'en',
                    title      => 'title',
                    message    => 'message',
                },
              ),
              'insert issue no IDs';

            eval {
                $db->txn(
                    sub {
                        $db->xdo(
                            insert_into => 'func_new_issue',
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
    my $child_update_id = $db->nextval('updates');

    ok $db->xdo(
        insert_into => 'func_new_issue',
        values      => {
            project_id => $pid,
            id         => $child_id,
            update_id  => $child_update_id,
            author     => 'y',
            email      => 'y',
            parent_id  => $id,
            lang       => 'en',
            title      => 'title',
            message    => 'message',
        },
      ),
      'insert child issue';

    is_deeply $db->selectrow_arrayref(
        'select name,path from projects
                 where id=?',
        undef, $child_id
      ),
      [ 'y', 'x/y' ], 'issues';

    is_deeply $db->selectrow_arrayref(
        'select project_id,parent_id,name
                 from project_deltas
                 where id=?',
        undef, $child_update_id
      ),
      [ $child_id, $id, 'y' ], 'issue_deltas';

=cut

            $update_id = $db->nextval('updates');
            ok $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id        => $id,
                    update_id => $update_id,
                    mtime     => $mtime + 3,
                    author    => 'y',
                    email     => 'y',
                    title     => 'newtitle',
                },
              ),
              'update issue title';

            is_deeply $db->selectrow_arrayref(
                'select title
         from topics
         where id=?',
                undef, $id
              ),
              ['newtitle'], 'issue title update';

            $update_id = $db->nextval('updates');

            ok $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id        => $id,
                    update_id => $update_id,
                    mtime     => $mtime + 4,
                    author    => 'y',
                    email     => 'y',
                    status_id => $needinfo_status_id,
                },
              ),
              'update issue status';

            is_deeply $db->selectrow_arrayref(
                'select
            project_issues.status_id,
            project_issues.update_id,
            issue_deltas.status_id
         from issue_deltas
         inner join project_issues
         on project_issues.issue_id = issue_deltas.issue_id
         where issue_deltas.id=?',
                undef, $update_id
              ),
              [ $needinfo_status_id, $update_id, $needinfo_status_id ],
              'issue_deltas';

            my $new_update_id = $db->nextval('updates');

            ok $db->xdo(
                insert_into => 'func_update_issue',
                values      => {
                    id        => $id,
                    update_id => $new_update_id,
                    mtime     => $mtime + 2,
                    author    => 'y',
                    email     => 'y',
                    status_id => $status_id,
                },
              ),
              'update issue status';

            is_deeply $db->selectrow_arrayref(
                'select
            project_issues.status_id,
            project_issues.update_id,
            issue_deltas.status_id
         from issue_deltas
         inner join project_issues
         on project_issues.issue_id = issue_deltas.issue_id
         where issue_deltas.id=?',
                undef, $new_update_id
              ),
              [ $needinfo_status_id, $update_id, $status_id ],
              'out of order issue_deltas';
        }
    );
};

done_testing();
