use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Digest::SHA qw/sha1_hex/;
use Test::Bif;
use Test::Fatal;
use Test::More;
use Time::Piece;

plan skip_all => 'need a rework';
exit;

run_in_tempdir {

    my $db = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    my $id        = $db->nextval('topics');
    my $update_id = $db->nextval('updates');
    my $mtime     = time;
    my $mtimetz   = int( Time::Piece->new->tzoffset );

    # We are unit-testing the function which will not succeed because
    # there is no matching project to satisfy foreign key constraints.
    # However because we use (require) these constraints to be initally
    # deferred, we can run and test them inside a transaction.

    my $res = undef;
    eval {
        $db->txn(
            sub {

                $db->deploy;
                ok $db->xdo(
                    insert_into => 'func_new_issue_status',
                    values      => {
                        id         => $id,
                        update_id  => $update_id,
                        project_id => -1,           # does not exist yet
                        mtime      => $mtime,
                        mtimetz    => $mtimetz,
                        author     => 'x',
                        email      => 'x',
                        lang       => 'en',
                        status     => 'a_status',
                        status     => 'a_status',
                        rank       => 10,
                        def        => 1,
                    },
                  ),
                  'new_issue_status';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz,title from topics where id=?',
                    undef, $id ),
                  [ $mtime, $mtimetz, 'a_status:a_status' ], 'topic';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz,author from updates where id=?',
                    undef, $update_id ),
                  [ $mtime, $mtimetz, 'x' ], 'topic update';

                is_deeply $db->selectrow_arrayref(
                    'select status,status,rank,def from issue_status
                     where id=?',
                    undef, $id
                  ),
                  [ qw/a_status a_status/, 10, 1 ], 'issue_status';

                is_deeply $db->selectrow_arrayref(
                    'select issue_status_id,status,status,rank,def
                     from issue_status_updates
                     where id=?',
                    undef, $update_id
                  ),
                  [ $id, qw/a_status a_status/, 10, 1 ], 'issue_status_updates';

                eval {
                    $db->txn(
                        sub {
                            $db->xdo(
                                insert_into => 'func_new_issue_status',
                                values      => {
                                    project_id => -1,     # does not exist yet
                                    author     => 'x2',
                                    email      => 'x2',
                                    lang       => 'en',
                                    status => 'b_status',
                                    status => 'a_status',
                                    rank   => 10,
                                    def    => 1,
                                },
                            );
                        }
                    );
                };

                like $@, qr/not unique/, 'duplicate failed';

                ok $db->xdo(
                    insert_into => 'func_update_issue_status',
                    values      => {
                        id      => $id,
                        author  => 'x',
                        email   => 'x',
                        mtime   => $mtime + 1,
                        mtimetz => $mtimetz + 1,
                        lang    => 'en',
                        status  => 'b_status',
                    },
                  ),
                  'update issue_status';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz from topics where id=?',
                    undef, $id ),
                  [ $mtime + 1, $mtimetz + 1 ],
                  'updated mtime';

                is_deeply $db->selectrow_arrayref(
                    'select count(id) from issue_status_updates
                    where issue_status_id=?',
                    undef,
                    $id
                  ),
                  [2], '2 issue_status updates';

                is_deeply $db->selectrow_arrayref(
                    'select status,status,rank,def from issue_status
                     where id=?',
                    undef, $id
                  ),
                  [ qw/a_status b_status/, 10, 1 ], 'updated issue_status';

                $res = 1;
            }
        );
    };

    my $err = $@;

  TODO: {
        local $TODO = 'need to rework';
        ok $err, 'transaction did not complete';
        ok $res, 'tests inside txn ok';
    }

    note($err) unless $res;
};

done_testing();
