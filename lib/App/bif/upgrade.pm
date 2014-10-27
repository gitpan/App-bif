package App::bif::upgrade;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $dbw  = $self->dbw;

    $dbw->txn(
        sub {
            my ( $old, $new ) = $dbw->deploy;
            $self->new_change( action => "upgrade from v$old to v$new" );

            if ( $new > $old ) {
                printf( "Database upgraded (v%s-v%s)\n", $old, $new );
            }
            else {
                printf( "Database remains at v%s\n", $new );
            }

            printf("Checking UUIDs");
            $self->dispatch('App::bif::check');
        }
    );

    return $self->ok('Upgrade');
}

1;
__END__

=head1 NAME

=for bif-doc #admin

bif-upgrade - upgrade a repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif upgrade [OPTIONS...]

=head1 DESCRIPTION

The B<bif-upgrade> command upgrades the current repository database to
match the running version of bif. Before the upgrade is committed the
L<bif-check> command is run to ensure the respository information is
consistent.

As an administration command, B<bif-upgrade> is only shown in usage
messages when the C<--help> option is used.

=head1 ARGUMENTS & OPTIONS

Global options only.

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

