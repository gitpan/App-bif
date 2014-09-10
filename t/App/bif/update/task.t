use strict;
use warnings;
use lib 't/lib';
use Test::Bif;
use Test::Fatal;
use Test::More;

run_in_tempdir {

    like exception { bif(qw/update task/) }, qr/usage:/, 'usage';
    isa_ok exception { bif(qw/update task 100/) }, 'Bif::Error::RepoNotFound';

    bif(qw/init/);

    isa_ok exception { bif(qw/update task 100/) }, 'Bif::Error::TopicNotFound';
    isa_ok exception { bif( qw/update task 1/, ); }, 'Bif::Error::WrongKind';

    my $p = bif(qw/ new project todo title --message m1 /);

    my $t = bif(qw/new task todo title --message m4/);

    my $u =
      bif( qw/update task/, $t->{id}, qw/closed --title title --message m4/ );

    isa_ok $u, 'Bif::OK::UpdateTask';
};

done_testing();
