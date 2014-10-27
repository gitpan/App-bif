package App::bif::drop::hub;
use strict;
use warnings;
use Bif::Mo;
use DBIx::ThinSQL qw/sq/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;
    my $info = $self->get_hub( $opts->{name} );

    if ( !$opts->{force} ) {
        print "Nothing dropped (missing --force, -f)\n";
        return $self->ok('DropNoForce');
    }

    my $uuid = substr( $info->{uuid}, 0, 8 );

    $dbw->txn(
        sub {
            $self->new_change(
                action  => "drop hub $info->{name} ($info->{id})",
                message => "    [  Dropped Hub:        ]\n"
                  . "    [    Name: $info->{name}  ]",
            );

            my $res = $dbw->xdo(
                delete_from => 'hubs',
                where       => { id => $info->{id} },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            if ($res) {
                print "Dropped hub: $info->{name} <$uuid>\n";
            }
            else {
                $self->err( 'NothingDropped', 'nothing dropped!' );
            }
        }
    );

    return $self->ok('DropHub');
}

1;
__END__

=head1 NAME

=for bif-doc #delete

bif-drop-hub - remove an hub from the repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif drop hub PATH [OPTIONS...]

=head1 DESCRIPTION

The bif-drop-hub command removes a hub from the repository.

=head1 ARGUMENTS

=over

=item PATH

A hub path or ID.

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

