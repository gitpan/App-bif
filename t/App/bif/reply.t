use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/reply/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/reply junk/) }, 'Bif::Error::RepoNotFound';

    my $db = bif(qw/init/);

    isa_ok exception { bif(qw/reply todo/) }, 'Bif::Error::UpdateNotFound';

    my $p = bif(qw/ new project todo --message message title /);

    isa_ok exception {
        bif( qw/reply /, "$p->{id}.$p->{update_id}" );
    }, 'Bif::Error::EmptyContent';

    subtest 'project', sub {

        my $update = bif(qw/update todo --message message2/);
        my $reply  = bif( qw/reply/, $update->{id} . '.' . $update->{update_id},
            '-m', 'message' );
        isa_ok $reply, 'Bif::OK::UpdateProject';

    };

    subtest 'task', sub {

        my $task   = bif(qw/new task todo title --message message3/);
        my $update = bif( qw/update/, $task->{id}, qw/ --message message4/ );
        my $reply  = bif( qw/reply /, $task->{id} . '.' . $task->{update_id},
            qw/-m message/ );

        isa_ok $reply, 'Bif::OK::UpdateTask';
    };

    subtest 'issue', sub {

        my $issue  = bif(qw/new issue todo title --message message5/);
        my $update = bif(
            qw/update/, $issue->{id}, qw/ --message
              message6/
        );
        my $reply = bif( qw/reply /, $issue->{id} . '.' . $issue->{update_id},
            qw/-m message/ );

        isa_ok $reply, 'Bif::OK::UpdateIssue';
    };

};

done_testing();
