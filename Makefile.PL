# devel/lib/ should only exist in the Git tree and is added to @INC here
# in order to pick up our Module::Install::PRIVATE::App_bif module. Can
# be ignored, and shouldn't have any effect on target machines
use lib 'devel/lib';

# libext/lib/perl5 is is added for in-tree execution with a local::lib
use lib 'libext/lib/perl5';
use inc::Module::Install;
use Cwd;
use FindBin '$Bin';
use Time::Piece;

my $VERSION = '0.1.0_11';

name 'App-bif';
abstract 'Distributed Project Management Tool';
author 'Mark Lawrence <nomad@null.net>';
license 'gpl_3';
homepage 'http://bifax.org/bif/';
bugtracker 'bif://bifax.org/bif/';
repository 'git://bifax.org/bif.git/';

version $VERSION;
perl_version '5.006';

install_share 'share';
install_script 'bin/bif';
install_script 'bin/bifsync';
install_docs;

cpanfile;

tests_recursive 't';
author_tests 'xt';

no_index package => 'Bif::DB::db';
no_index package => 'Bif::DB::st';
no_index package => 'Bif::DB::RW::db';
no_index package => 'Bif::DB::RW::st';
no_index package => 'Bif::Mo';
no_index package => 'Bif::OK';
no_index package => 'Bif::Error';

WriteAll;

# Create a t/bif script for testing
{
    open( FH, '>', 't/bif' ) or die "open: $!";
    print FH <<"END";
#!$^X
use strict;
use lib "$Bin/libext/lib/perl5";
use lib "$Bin/lib";
use OptArgs qw/dispatch/;

# Make sure that any subcommands that call bifsync locally find the
# local testing version in t/bifsync
\$ENV{PATH} = "$Bin/t" .':'.\$ENV{PATH};

\$main::BIF_SHARE_DIR = "$Bin/share";

dispatch(qw/run App::bif/);
END
    close FH;
    chmod 0755, 't/bif' or warn "chmod: $!";

    use Path::Tiny;
    my $pod = path('bin/bif')->slurp_utf8;
    $pod =~ s/.*__END__//sm;
    path('t/bif')->append_utf8($pod);
}

# Create a t/bifsync script for testing
{
    open( FH, '>', 't/bifsync' ) or die "open: $!";
    print FH <<"END";
#!$^X
use strict;
use lib "$Bin/libext/lib/perl5";
use lib "$Bin/lib";
use OptArgs qw/dispatch/;

dispatch(qw/run App::bifsync/);
END
    close FH;
    chmod 0755, 't/bifsync' or warn "chmod: $!";

    my $pod = path('bin/bifsync')->slurp_utf8;
    $pod =~ s/.*__END__//sm;
    path('t/bifsync')->append_utf8($pod);
}

# Set App::bif::Version if we are a developer
exit unless -d '.git';

my $commit = qx/git rev-parse HEAD/;
chomp $commit;
my $branch .= qx/git rev-parse --abbrev-ref HEAD/;
chomp $branch;

my $t    = gmtime;
my $when = $t->ymd . ' ' . $t->hms;

open( FH, '>', 'lib/App/bif/Version.pm' ) or die "open: $!";
print FH <<"END";
package App::bif::Version;
\$App::bif::Version::VERSION = '$VERSION';
\$App::bif::Version::COMMIT = '$commit';
\$App::bif::Version::BRANCH = '$branch';
\$App::bif::Version::DATE = '$when';
1;
END

