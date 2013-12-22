use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log /) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    is bif(qw/log/), 'Log', 'log nothing';

    isa_ok exception { bif(qw/ log unknown /) }, 'Bif::Error::TopicNotFound';

    my $p1 = bif(qw/ new project todo --message message title /);

    # ID number 2 should be a project_status
    isa_ok exception { bif(qw/ log 2 /) }, 'Bif::Error::LogUnimplemented';

    is bif(qw/log todo/), 'LogProject', 'log project';

    my $t = bif(qw/ new task todo --message message title /);
    is bif( qw/log/, $t->{id} ), 'LogTask', 'log task';

    my $i = bif(qw/ new issue todo --message message title /);
    is bif( qw/log/, $i->{id} ), 'LogIssue', 'log issue';
};

done_testing();
