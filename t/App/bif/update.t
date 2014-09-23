use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/update junk/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);
    isa_ok exception { bif(qw/update todo/) }, 'Bif::Error::TopicNotFound';

    my $p = bif(qw/ new project todo --message m1 title /);
    my $u = bif(qw/update todo --message m2/);
    isa_ok $u, 'Bif::OK::ChangeProject';

    my $t = bif(qw/new task todo title --message m3/);
    $u = bif( qw/update/, $t->{id}, qw/--message m4/ );
    isa_ok $u, 'Bif::OK::ChangeTask';

    my $i = bif(qw/new issue todo title --message m5/);
    $u = bif( qw/update/, $i->{id}, qw/--message m6/ );
    isa_ok $u, 'Bif::OK::ChangeIssue';
};

done_testing();
