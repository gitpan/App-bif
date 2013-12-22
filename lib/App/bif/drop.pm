package App::bif::drop;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_dbw;

    my $info =
         $db->get_topic( $opts->{id} )
      || $db->get_update( $opts->{id} )
      || $db->get_project( $opts->{id} )
      || bif_err( 'TopicNotFound',
        'topic, update or project not found: ' . $opts->{id} );

    if ( !$opts->{force} ) {
        print "Nothing dropped (missing --force, -f)\n";
        return bif_ok('DropNoForce');
    }

    if ( $info->{update_id} ) {

        $db->xdo(
            delete_from => 'updates',
            where       => { id => $info->{update_id} },
        );

        print "Dropped: $info->{kind} $info->{id}.$info->{update_id}\n";
        return bif_ok( 'Drop' . ucfirst( $info->{kind} ) . 'Update', $info );
    }
    else {

        $db->xdo(
            delete_from => $info->{kind} . 's',
            where       => { id => $info->{id} },
        );

        print "Dropped: $info->{kind} $info->{id}\n";
        return bif_ok( 'Drop' . ucfirst( $info->{kind} ), $info );
    }
}

1;
__END__

=head1 NAME

bif-drop - delete a topic or topic update

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif drop ID [OPTIONS...]

=head1 DESCRIPTION

Delete a thread or thread update from the database. This really only
makes sense if what you wish to drop does not exist on a hub somewhere,
otherwise the next time you sync it would come back from the dead to
haunt you.

Drop is a hidden command that only appears in usage messages when
C<--help> (C<-h>) is given.

=head1 ARGUMENTS

=over

=item ID

Either a thread ID, a thread update ID, or a project PATH. Required.

=back

=head1 OPTIONS

=over

=item --force, -f

Actually do the drop. This option is required as a safety measure to
stop you shooting yourself in the foot.

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

