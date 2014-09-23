use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log /) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok bif(qw/log/), 'Bif::OK::LogRepoTime', 'log nothing gives repo';

    isa_ok exception { bif(qw/ log unknown /) }, 'Bif::Error::TopicNotFound';

    my $p1     = bif(qw/ new project todo --message m1 title /);
    my $change = bif(qw/update todo -m meh/);

    isa_ok bif(qw/log todo/), 'Bif::OK::LogProject';

    my $t = bif(qw/ new task todo --message m2 title /);
    $change = bif( qw/update/, $t->{id}, qw/-m taskmeh/ );
    isa_ok bif( qw/log/, $t->{id} ), 'Bif::OK::LogTask';

    my $i = bif(qw/ new issue todo --message m3 title /);
    $change = bif( qw/update/, $i->{id}, qw/-m issuemeh/ );
    isa_ok bif( qw/log/, $i->{id} ), 'Bif::OK::LogIssue';
};

done_testing();
