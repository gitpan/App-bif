use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update issue/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/update issue 100/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/update issue 100/) }, 'Bif::Error::TopicNotFound';
    isa_ok exception { bif( qw/update issue 1/, ); }, 'Bif::Error::WrongKind';

    my $p = bif(qw/ new project todo title --message m1 /);

    my $t = bif(qw/new issue todo title --message m4/);

    my $u =
      bif( qw/update issue/, $t->{id}, qw/closed --title title --message m4/ );

    isa_ok $u, 'Bif::OK::UpdateIssue';
};

done_testing();
