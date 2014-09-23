use strict;
use warnings;
use lib 't/lib';
use Bif::DBW;
use Digest::SHA qw/sha1_hex/;
use List::Util qw/sum/;
use Test::Bif;
use Test::More;
use Data::Dumper;

plan skip_all => 'to be redone';
exit;

sub rehash {
    my $table = shift;
    my $row   = shift;    # id, prefix, hash, num_changes

    my $prefix = $row->{prefix};
    while ( length($prefix) >= 1 ) {
        $table = [ grep { $_->{prefix} ne $prefix } @$table ];
        $prefix = substr( $prefix, 0, length($prefix) - 1 );
    }

    push( @$table, $row ) if $row->{num_changes};

    $prefix = $row->{prefix};
    while ( length($prefix) > 1 ) {
        my $new = substr( $prefix, 0, length($prefix) - 1 );

        my @list = grep { $_->{prefix} =~ /^$new.$/ } @$table;

        my $hash =
          substr( sha1_hex( sort map { $_->{hash} } @list ), 0, 8 );

        my $sum = sum( map { $_->{num_changes} } @list );

        push(
            @$table,
            {
                project_id  => $row->{project_id},
                prefix      => $new,
                hash        => $hash,
                num_changes => $sum
            }
        ) if $sum;

        $prefix = $new;
    }

    return [ sort { $a->{prefix} cmp $b->{prefix} } @$table ];
}

sub test_topic_hash {
    my $merkle = shift;
    my $p1     = shift;
    my $db     = shift;

    my $result = $db->xarrayref(
        select => [qw/hash num_changes/],
        from   => 'projects',
        where  => { id => $p1->{project_id} },
    );

    my $hash = substr(
        sha1_hex(
            map  { $_->{hash} }
            sort { $a->{hash} cmp $b->{hash} }
            grep { length( $_->{prefix} ) == 1 } @$merkle
        ),
        0, 8
    );

    my $num_changes = sum(
        map  { $_->{num_changes} }
        grep { length( $_->{prefix} ) == 1 } @$merkle
    );

    is_deeply $result, [ $hash, $num_changes ], 'topic change ok';

}

run_in_tempdir {

    my $db = Bif::DBW->connect('dbi:SQLite:dbname=db.sqlite3');

    my $res = undef;
    eval {
        $db->txn(
            sub {
                $db->deploy;
                my $change  = new_test_change($db);
                my $project = new_test_project($db);

                my $p1 = {
                    project_id  => $project->{id},
                    prefix      => 'abcde',
                    hash        => sha1_hex('abcde'),
                    num_changes => 13,
                };
                my $merkle = rehash( [], $p1 );

                $db->xdo(
                    insert_into => 'project_related_changes_merkle',
                    values      => $p1,
                );

                my $result = $db->xhashrefs(
                    select   => [qw/project_id prefix hash num_changes/],
                    from     => 'project_related_changes_merkle',
                    order_by => 'prefix',
                );

                is_deeply $result, $merkle, 'project_related_changes_merkle';
                test_topic_hash( $merkle, $p1, $db );

                $p1 = {
                    project_id  => $project->{id},
                    prefix      => 'ab1de',
                    hash        => sha1_hex('ab1de'),
                    num_changes => 2,
                };
                $merkle = rehash( $merkle, $p1 );

                $db->xdo(
                    insert_into => 'project_related_changes_merkle',
                    values      => $p1,
                );

                $result = $db->xhashrefs(
                    select   => [qw/project_id prefix hash num_changes/],
                    from     => 'project_related_changes_merkle',
                    order_by => 'prefix',
                );

                is_deeply $result, $merkle, 'shared parentage';
                test_topic_hash( $merkle, $p1, $db );

                # simulate a delete
                $p1->{num_changes} = 0;
                $merkle = rehash( $merkle, $p1 );

                $db->xdo(
                    insert_into => 'project_related_changes_merkle',
                    values      => $p1,
                );

                $result = $db->xhashrefs(
                    select   => [qw/project_id prefix hash num_changes/],
                    from     => 'project_related_changes_merkle',
                    order_by => 'prefix',
                );

                is_deeply $result, $merkle,
                  '"delete" from project_related_changes_merkle';
                test_topic_hash( $merkle, $p1, $db );

                $res = 1;
            }
        );
    };

    diag($@) unless $res;

    ok $res, 'tests inside txn ok';

};

done_testing();
