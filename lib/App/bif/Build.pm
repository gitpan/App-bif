package App::bif::Build;
$App::bif::Build::VERSION = '0.1.0_13';
$App::bif::Build::COMMIT = '9cda1bf5932e461cbf2bf73298132f7d95cf8cac';
$App::bif::Build::BRANCH = 'devel';
$App::bif::Build::DATE = '2014-04-23 14:10:55';
1;
__END__

=head1 NAME

App::bif::Build - build-time constants for App-bif

=head1 VERSION

0.1.0_13 (2014-04-23)

=head1 SYNOPSIS

    use App::bif::Build

    # Do something with:
    #  $App::bif::Build::BRANCH
    #  $App::bif::Build::COMMIT
    #  $App::bif::Build::DATE
    #  $App::bif::Build::VERSION

=head1 DESCRIPTION

B<App::bif::Build> is generated when Makefile.PL is run in the bif
source tree and simply contains 4 scalar variables. The variables are
used by the C<bif show VERSION> command to display relevant build
information.

When this version of App-bif was built the variables were set as
follows:

=over

=item $App::bif::Build::BRANCH = "devel"

The Git branch name which was current when the App-bif distribution was
created.

=item $App::bif::Build::COMMIT = "9cda1bf5932e461cbf2bf73298132f7d95cf8cac"

The Git commit hash at the head of the branch when the App-bif
distribution was created.

=item $App::bif::Build::DATE = "2014-04-23 14:10:55"

The UTC date that the Makefile.PL file was run.

=item $App::bif::Build::VERSION = "0.1.0_13"

The version of the App-bif distribution.

=back

=head1 SEE ALSO

L<bif-show>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

