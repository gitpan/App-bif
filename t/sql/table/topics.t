use strict;
use warnings;
use lib 't/lib';
use Bif::DB::RW;
use Digest::SHA qw/sha1_hex/;
use Test::Bif;
use Test::Fatal;
use Test::More;
use Time::Piece;

plan skip_all => 'Need to rework';

run_in_tempdir {

    bif('init');
    my $db = Bif::DB::RW->connect('dbi:SQLite:dbname=.bif/db.sqlite3');

    my $id        = $db->nextval('topics');
    my $update_id = $db->nextval('updates');
    my $mtime     = time;
    my $mtimetz   = int( Time::Piece->new->tzoffset );

    like exception {
        $db->xdo(
            insert_into => 'func_new_topic',
            values      => {
                kind   => undef,    # shouldn't be NULL
                author => 'x',

                # email  => 'x', # shouldn't be missing
                title => 'x2',
            },
        );
    }, qr/may not be NULL/, 'insert missing values';

    ok $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            id          => $id,
            update_id   => $update_id,
            mtime       => $mtime,
            mtimetz     => $mtimetz,
            kind        => 'test',
            author      => 'x',
            email       => 'x',
            lang        => 'en',
            title       => 'title',
            message     => 'message',
            hash_extras => 'stuff',
        },
      ),
      'insert topic';

    my $uuid = sha1_hex(
        'test',  $mtime,    $mtimetz, 'x', 'x', 'en',
        'title', 'message', 'stuff'
    );

    is_deeply $db->selectrow_arrayref( 'select uuid from topics where id=?',
        undef, $id ),
      [$uuid], 'sha match';

    is_deeply $db->selectrow_arrayref( 'select uuid from updates where id=?',
        undef, $update_id ),
      [$uuid], 'update sha match';

    is_deeply $db->selectrow_arrayref(
        'select mtime,mtimetz,title from topics where id=?',
        undef, $id ),
      [ $mtime, $mtimetz, 'title' ], 'topic';

    is_deeply $db->selectrow_arrayref(
        'select mtime,mtimetz,author from updates where id=?',
        undef, $update_id ),
      [ $mtime, $mtimetz, 'x' ], 'topic update';

    like exception {
        $db->xdo(
            insert_into => 'func_new_topic',
            values      => {
                mtime       => $mtime,
                mtimetz     => $mtimetz,
                kind        => 'test',
                author      => 'x',
                email       => 'x',
                lang        => 'en',
                title       => 'title',
                message     => 'message',
                hash_extras => 'stuff',
            },
        );
    }, qr/uuid is not unique/, 'duplicate uuid fail';

    my $parent_update_id = $update_id;
    $update_id = $db->nextval('updates');

    ok $db->xdo(
        insert_into => 'func_update_topic',
        values      => {
            id          => $id,
            update_id   => $update_id,
            author      => 'x',
            email       => 'x',
            mtime       => $mtime + 1,
            mtimetz     => $mtimetz + 1,
            lang        => 'en',
            title       => 'title2',
            message     => 'a message',
            hash_extras => 'morestuff',
        },
      ),
      'update topic';

    my $update_uuid = sha1_hex(
        $uuid,       $uuid, $mtime + 1, $mtimetz + 1,
        'x',         'x',   'en',       'title2',
        'a message', 'morestuff'
    );

    is_deeply $db->selectrow_arrayref(
        'select uuid,parent_id from updates where id=?',
        undef, $update_id ),
      [ $update_uuid, $parent_update_id ], 'update sha and parent_id match';

    $db->selectrow_arrayref(q{select debug('select * from updates')});

    is_deeply $db->selectrow_arrayref(
        'select mtime,mtimetz,title from topics where id=?',
        undef, $id ),
      [ $mtime + 1, $mtimetz + 1, 'title2' ],
      'updated title';

    is_deeply $db->selectrow_arrayref(
        'select count(id) from updates
        where topic_id=?',
        undef,
        $id
      ),
      [2], '2 updates';

    my $new_update_id = $db->nextval('updates');

    ok $db->xdo(
        insert_into => 'func_update_topic',
        values      => {
            id               => $id,
            update_id        => $new_update_id,
            parent_update_id => $update_id,
            author           => 'x',
            email            => 'x',
            mtime            => $mtime + 2,
            mtimetz          => $mtimetz + 2,
            lang             => 'en',
            title            => 'title2',
            message          => 'a message',
        },
      ),
      'update topic';

    my $sha1_hex = sha1_hex(
        $uuid, $update_uuid, $mtime + 2, $mtimetz + 2,
        'x',   'x',          'en',       'title2',
        'a message',
    );

    is_deeply $db->selectrow_arrayref( 'select uuid from updates where id=?',
        undef, $new_update_id ),
      [$sha1_hex], 'update sha match with parent_uuid';

    $update_id = $db->nextval('updates');
    ok $db->xdo(
        insert_into => 'func_update_topic',
        values      => {
            id        => $id,
            update_id => $update_id,
            author    => 'x',
            email     => 'x',
            mtime     => $mtime + 1,
            mtimetz   => $mtimetz + 1,
            lang      => 'en',
            title     => 'earlier title',
        },
      ),
      'update topic earlier';

    is_deeply $db->selectrow_arrayref(
        'select
            topics.title,
            topics.mtime,
            updates.title
        from updates
        inner join topics
        on topics.id = updates.topic_id
        where updates.id=?',
        undef, $update_id
      ),
      [ 'title2', $mtime + 2, 'earlier title' ], 'out of order update ok';

    ok $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            kind   => 'test',
            author => 'x',
            email  => 'x',
            title  => 'x2',
        },
      ),
      'insert topic no IDs';

};

done_testing();
