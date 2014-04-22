# util/lib/ should only exist in the Git tree and is added to @INC here
# in order to pick up our Module::Install::PRIVATE::App_bif module. Can
# be ignored, and shouldn't have any effect on target machines
use lib 'util/lib';

use inc::Module::Install;
use Cwd;
use FindBin '$Bin';
use Time::Piece;

my $VERSION = '0.1.0_12';

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
no_index package => 'Bif::DBW::db';
no_index package => 'Bif::DBW::st';
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

# Setup App::bif::Build if we are a developer
exit unless -d '.git';

my $commit = qx/git rev-parse HEAD/;
chomp $commit;
my $branch .= qx/git rev-parse --abbrev-ref HEAD/;
chomp $branch;

my $t    = gmtime;
my $when = $t->ymd . ' ' . $t->hms;

open( FH, '>', 'lib/App/bif/Build.pm' ) or die "open: $!";
print FH <<"THE_END";
package App::bif::Build;
\$App::bif::Build::VERSION = '$VERSION';
\$App::bif::Build::COMMIT = '$commit';
\$App::bif::Build::BRANCH = '$branch';
\$App::bif::Build::DATE = '$when';
1;
__END__

=head1 NAME

App::bif::Build - build-time constants for App-bif

=head1 VERSION

0.1.0_12 (2014-04-22)

=head1 SYNOPSIS

    use App::bif::Build

    # Do something with:
    #  \$App::bif::Build::BRANCH
    #  \$App::bif::Build::COMMIT
    #  \$App::bif::Build::DATE
    #  \$App::bif::Build::VERSION

=head1 DESCRIPTION

B<App::bif::Build> is generated when Makefile.PL is run in the bif
source tree and simply contains 4 scalar variables. The variables are
used by the C<bif show VERSION> command to display relevant build
information.

When this version of App-bif was built the variables were set as
follows:

=over

=item \$App::bif::Build::BRANCH = "$branch"

The Git branch name which was current when the App-bif distribution was
created.

=item \$App::bif::Build::COMMIT = "$commit"

The Git commit hash at the head of the branch when the App-bif
distribution was created.

=item \$App::bif::Build::DATE = "$when"

The UTC date that the Makefile.PL file was run.

=item \$App::bif::Build::VERSION = "$VERSION"

The version of the App-bif distribution.

=back

=head1 SEE ALSO

L<bif-show>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad\@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad\@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

THE_END

