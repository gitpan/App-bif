# devel/lib/ should only exist in the Git tree and is added to @INC here
# in order to pick up our Module::Install::PRIVATE::App_bif module. Can
# be ignored, and shouldn't have any effect on target machines
use lib 'devel/lib';

# extlib/lib/perl5 is is added for in-tree execution with a local::lib
use lib 'extlib/lib/perl5';
use inc::Module::Install;

name 'App-bif';
abstract 'Distributed Project Management Tool';
author 'Mark Lawrence <nomad@null.net>';
license 'gpl_3';
homepage 'http://bifax.org/bif/';
bugtracker 'bif://bifax.org/bif/';
repository 'git://bifax.org/bif.git/';

version '0.1.0_1';
perl_version '5.006';

tests_recursive 't';
author_tests 'xt';

install_share 'share';

install_script 'bin/bif';
install_script 'bin/bifsync';

install_docs;

cpanfile;

WriteAll;

# Create the test scripts if we are a developer
exit unless -d '.git';

require Cwd;
my $dir = Cwd::abs_path;
open( FH, '>', 't/bif' ) or die "open: $!";
print FH <<"END";
#!$^X
use strict;
use FindBin qw/\$Bin/;
use lib "\$Bin/../extlib/lib/perl5";
use lib "\$Bin/../lib";
use Path::Tiny;
use OptArgs qw/dispatch/;

# Make sure that any subcommands that call bifsync locally find the
# local testing version in t/bifsync
\$ENV{PATH} = \$Bin .':'.\$ENV{PATH};

\$Test::Bif::SHARE_DIR = path('$dir', 'share');

dispatch(qw/run App::bif/);
END
close FH;
chmod 0755, 't/bif' or warn "chmod: $!";

use Path::Tiny;
my $pod = path('bin/bif')->slurp_utf8;
$pod =~ s/.*__END__//sm;
path('t/bif')->append_utf8($pod);

open( FH, '>', 't/bifsync' ) or die "open: $!";
print FH <<"END";
#!$^X
use strict;
use FindBin qw/\$Bin/;
use lib "\$Bin/../extlib/lib/perl5";
use lib "\$Bin/../lib";
use OptArgs qw/dispatch/;

dispatch(qw/run App::bifsync/);
END
close FH;
chmod 0755, 't/bifsync' or warn "chmod: $!";

$pod = path('bin/bifsync')->slurp_utf8;
$pod =~ s/.*__END__//sm;
path('t/bifsync')->append_utf8($pod);

