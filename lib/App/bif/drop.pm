package App::bif::drop;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

1;
__END__

=head1 NAME

=for bif-doc #delete

bif-drop - delete a topic or topic change

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif drop ITEM ID [OPTIONS...]

=head1 DESCRIPTION

Delete a topic or an change from the database. This really only makes
sense if what you wish to drop does not exist on a hub somewhere,
otherwise the next time you sync it would come back from the dead to
haunt you.

There is a difference between dropping a project that is local only,
and a project that exists on a hub. The same goes for issues which
exists in multiple projects. See the respective bif-drop-* pages for
details.

Drop is a hidden command that only appears in usage messages when
C<--help> (C<-h>) is given.

=head1 ARGUMENTS

=over

=item ITEM

A topic type such as issue, task, change, etc.

=back

=item ID

Either a topic ID, an change cID, or a project PATH. Required.

=back

=head1 OPTIONS

=over

=item --force, -f

Actually do the drop. This option is required as a safety measure to
stop you shooting yourself in the foot.

=back

=head1 SEE ALSO

L<bif-drop-issue>(1), L<bif-drop-project>(1), L<bif-drop-task>(1), L<bif-drop-change>(1), L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

