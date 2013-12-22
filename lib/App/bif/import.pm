package App::bif::import;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);

    # Consider upping PRAGMA cache_size? Or handle that in Bif::Sync?
    my $db = bif_dbw;

    bif_err( 'NotImplemented', 'import not implemented yet' );
}

1;
__END__

=head1 NAME

bif-import -  import projects from a remote hub

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif import HUB [PATHS...] [OPTIONS...]

=head1 DESCRIPTION

Import projects from a hub.

=head1 ARGUMENTS

=over

=item HUB

The location of a remote hub or a previously defined alias.

=item PATHS...

The paths of the remote projects to import. If not given then all
projects will be imported. An error will be raised if a project with
the same path exists locally.

=back

=head1 OPTIONS

=over

=item --alias

Create an alias for C<HUB> which can be used in future calls to
C<import> or C<export>. Typically this would be the name of the
organisation that owns or manages the hub.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

