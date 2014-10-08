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

    # We are unit-testing the function which will not succeed because
    # there is no matching project to satisfy foreign key constraints.
    # However because we use (require) these constraints to be initally
    # deferred, we can run and test them inside a transaction.

    my $res = undef;
    my $db  = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    eval {
        $db->txn(
            sub {
                $db->deploy;

                my $id        = $db->nextval('topics');
                my $change_id = $db->nextval('changes');
                my $mtime     = time;
                my $mtimetz   = int( Time::Piece->new->tzoffset );

                ok $db->xdo(
                    insert_into => 'func_new_project_status',
                    values      => {
                        id         => $id,
                        change_id  => $change_id,
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
                  'new_project_status';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz,title from topics where id=?',
                    undef, $id ),
                  [ $mtime, $mtimetz, 'a_status:a_status' ], 'topic';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz,author from changes where id=?',
                    undef, $change_id ),
                  [ $mtime, $mtimetz, 'x' ], 'topic change';

                is_deeply $db->selectrow_arrayref(
                    'select status,status,rank,def from project_status
                     where id=?',
                    undef, $id
                  ),
                  [ qw/a_status a_status/, 10, 1 ], 'project_status';

                is_deeply $db->selectrow_arrayref(
                    'select project_status_id,status,status,rank,def
                     from project_status_deltas
                     where id=?',
                    undef, $change_id
                  ),
                  [ $id, qw/a_status a_status/, 10, 1 ],
                  'project_status_deltas';

                eval {
                    $db->txn(
                        sub {
                            $db->xdo(
                                insert_into => 'func_new_project_status',
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
                    insert_into => 'func_update_project_status',
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
                  'change project_status';

                is_deeply $db->selectrow_arrayref(
                    'select mtime,mtimetz from topics where id=?',
                    undef, $id ),
                  [ $mtime + 1, $mtimetz + 1 ],
                  'changed mtime';

                is_deeply $db->selectrow_arrayref(
                    'select count(id) from project_status_deltas
                    where project_status_id=?',
                    undef,
                    $id
                  ),
                  [2], '2 project_status changes';

                is_deeply $db->selectrow_arrayref(
                    'select status,status,rank,def from project_status
                     where id=?',
                    undef, $id
                  ),
                  [ qw/a_status b_status/, 10, 1 ], 'changed project_status';

                $res = 1;
            }
        );
    };

    my $err = $@;
    ok $err, 'transaction did not complete';
    ok $res, 'tests inside txn ok';

    note($err) unless $res;

};

done_testing();
