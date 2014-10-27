# util/lib/ should only exist in the Git tree and is added to @INC here
# in order to pick up our Module::Install::PRIVATE::App_bif module. Can
# be ignored, and shouldn't have any effect on target machines
use lib 'util/lib';

use 5.010;
use inc::Module::Install;
use Cwd;
use FindBin '$Bin';
use Time::Piece;
my $VERSION = '0.1.4';

name 'App-bif';
abstract 'Distributed Project Management Tool';
author 'Mark Lawrence <nomad@null.net>';
license 'gpl_3';
homepage 'http://bifax.org/bif/';
bugtracker 'bif://bifax.org/bif/';
repository 'git://bifax.org/bif.git/';

version $VERSION;
perl_version '5.010';

readme_from 'lib/bif-doc-about.pod';

install_share 'share';
install_script 'bin/bif';
install_script 'bin/bifsync';
install_docs;

cpanfile;

tests_recursive 't';
author_tests 'xt';

no_index package => 'Bif::DB::db';
no_index package => 'Bif::DB::st';
no_index package => 'Bif::DBW::db';
no_index package => 'Bif::DBW::st';
no_index package => 'Bif::OK';
no_index package => 'Bif::Error';

WriteAll;

# Create t/bif* scripts for testing
{
    use Path::Tiny;
    my $bif     = path( $Bin, 'bin', 'bif' );
    my $bifsync = path( $Bin, 'bin', 'bifsync' );
    my $lib     = path( $Bin, 'lib' );
    my $share   = path( $Bin, 'share' );
    my $tbin    = path( $Bin, 'tbin' );
    my $tbif    = $tbin->child('bif');
    my $tbifu   = $tbin->child('bifu');
    my $tbifsync = $tbin->child('bifsync');

    mkdir $tbin;

    # Setup test bif

    my $sep = $^O eq 'MSWin32' ? ';' : ':';

    $tbif->spew_utf8(<<EOF);
#!$^X
use strict;
use lib "$lib";
use App::bif::OptArgs;
use OptArgs qw/class_optargs/;

# Make sure that any subcommands that call bifsync locally find the
# local testing version in t/bifsync
\$ENV{PATH} = "$tbin" .'$sep'.\$ENV{PATH};

\$main::BIF_SHARE_DIR = "$share";

my ( \$class, \$opts ) = class_optargs('App::bif');
\$class->new( opts => \$opts )->run;

__END__
EOF
    chmod 0755, $tbif or warn "chmod: $!";

    my $pod = $bif->slurp_utf8;
    $pod =~ s/.*__END__//sm;
    $tbif->append_utf8($pod);

    # Setup test bifu

    $tbifu->spew_utf8(<<EOF);
#!$^X
use strict;
use lib "$lib";
use App::bif::OptArgs;
use OptArgs qw/class_optargs/;

# Make sure that any subcommands that call bifsync locally find the
# local testing version in t/bifsync
\$ENV{PATH} = "$tbin" .'$sep'.\$ENV{PATH};

\$main::BIF_SHARE_DIR = "$share";

push(\@ARGV, '--user-repo');

my ( \$class, \$opts ) = class_optargs('App::bif');
\$class->new( opts => \$opts )->run;

__END__
EOF
    chmod 0755, $tbifu or warn "chmod: $!";

    my $pod = $bif->slurp_utf8;
    $pod =~ s/.*__END__//sm;
    $tbif->append_utf8($pod);

    # Setup test bifsync

    $tbifsync->spew_utf8(<<EOF);
#!$^X
use strict;
use lib "$lib";
use OptArgs qw/class_optargs/;

my ( \$class, \$opts ) = OptArgs::class_optargs('App::bifsync');
\$class->new( opts => \$opts )->run;

__END__
EOF
    chmod 0755, $tbifsync or warn "chmod: $!";

    $pod = $bifsync->slurp_utf8;
    $pod =~ s/.*__END__//sm;
    $tbifsync->append_utf8($pod);
}

# Setup App::bif::Build if we are a developer
exit unless -d '.git';

my $commit = qx/git rev-parse HEAD/;
chomp $commit;

my $t    = gmtime;
my $when = $t->ymd . ' ' . $t->hms;

my $str = <<EOF;
HIDDENpackage App::bif::Build;
HIDDENuse strict;
HIDDENuse warnings;
HIDDEN\$App::bif::Build::VERSION = '$VERSION';
HIDDEN\$App::bif::Build::COMMIT = '$commit';
HIDDEN\$App::bif::Build::DATE = '$when';
HIDDEN\$App::bif::Build::FILE = __FILE__;
HIDDEN1;
HIDDEN__END__
HIDDEN
HIDDEN=head1 NAME
HIDDEN
HIDDENApp::bif::Build - build-time constants for App-bif
HIDDEN
HIDDEN=head1 VERSION
HIDDEN
HIDDEN0.1.0_28 (2014-10-27)
HIDDEN
HIDDEN=head1 SYNOPSIS
HIDDEN
HIDDEN    use App::bif::Build
HIDDEN
HIDDEN    # Do something with:
HIDDEN    #  \$App::bif::Build::BRANCH
HIDDEN    #  \$App::bif::Build::COMMIT
HIDDEN    #  \$App::bif::Build::DATE
HIDDEN    #  \$App::bif::Build::FILE
HIDDEN    #  \$App::bif::Build::VERSION
HIDDEN
HIDDEN=head1 DESCRIPTION
HIDDEN
HIDDENB<App::bif::Build> is generated when the App-bif distribution is
HIDDENcreated from the bif
HIDDENsource tree and simply contains 5 scalar variables. The variables are
HIDDENused by the C<bif show VERSION> command to display relevant build
HIDDENinformation.
HIDDEN
HIDDENWhen this version of App-bif was built and installed the variables
HIDDENwere set as follows:
HIDDEN
HIDDEN=over
HIDDEN
HIDDEN=item \$App::bif::Build::COMMIT = "$commit"
HIDDEN
HIDDENThe Git commit hash at the head of the branch when the App-bif
HIDDENdistribution was created.
HIDDEN
HIDDEN=item \$App::bif::Build::DATE = "$when"
HIDDEN
HIDDENThe UTC date that the Makefile.PL file was run.
HIDDEN
HIDDEN=item \$App::bif::Build::FILE
HIDDEN
HIDDENThe installation location of this module, which cannot be
HIDDENdocumented here as it is only known at runtime.
HIDDEN
HIDDEN=item \$App::bif::Build::VERSION = "$VERSION"
HIDDEN
HIDDENThe version of the App-bif distribution.
HIDDEN
HIDDEN=back
HIDDEN
HIDDEN=head1 SEE ALSO
HIDDEN
HIDDENL<bif-show>(1)
HIDDEN
HIDDEN=head1 AUTHOR
HIDDEN
HIDDENMark Lawrence E<lt>nomad\@null.netE<gt>
HIDDEN
HIDDEN=head1 COPYRIGHT AND LICENSE
HIDDEN
HIDDENCopyright 2014 Mark Lawrence <nomad\@null.net>
HIDDEN
HIDDENThis program is free software; you can redistribute it and/or modify it
HIDDENunder the terms of the GNU General Public License as published by the
HIDDENFree Software Foundation; either version 3 of the License, or (at your
HIDDENoption) any later version.
HIDDEN
EOF

$str =~ s/^HIDDEN//mg;
path(qw/lib App bif Build.pm/)->spew_utf8($str);

