package App::bif::drop::update;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_update( $self->{uid} );

    if ( !$self->{force} ) {
        print "Nothing dropped (missing --force, -f)\n";
        return $self->ok('DropNoForce');
    }

    my $uuid = substr( $info->{uuid}, 0, 8 );

    $db->txn(
        sub {
            $self->new_update(
                message => '',
                action  => "drop update u$info->{id} <$uuid>",
            );

            my $res = $db->xdo(
                delete_from => 'updates',
                where       => { id => $info->{id} },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            if ($res) {
                print "Dropped update: $self->{uid} <$uuid>\n";
            }
            else {
                $self->err( 'NothingDropped', 'nothing dropped!' );
            }
        }
    );

    return $self->ok('DropUpdate');
}

1;
__END__

=head1 NAME

bif-drop-update - remove an update from the repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif drop update UID [OPTIONS...]

=head1 DESCRIPTION

The bif-drop-update command removes an update from the repository.

=head1 ARGUMENTS

=over

=item UID

An update ID of the form "u23".

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

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

