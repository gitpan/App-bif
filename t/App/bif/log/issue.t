use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    isa_ok exception { bif(qw/ log issue /) },  'OptArgs::Usage';
    isa_ok exception { bif(qw/ log issue 1/) }, 'Bif::Error::UserRepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/log issue 1311/) }, 'Bif::Error::TopicNotFound';

    my $p1 = bif(qw/ new project todo --message m1 title /);

    isa_ok exception { bif( qw/ log issue /, $p1->{id} ) },
      'Bif::Error::WrongKind';

    my $i1 = bif(qw/new issue title -m m2 /);

    isa_ok bif( qw/ log issue /, $i1->{id} ), 'Bif::OK::LogIssue';

};

done_testing();
