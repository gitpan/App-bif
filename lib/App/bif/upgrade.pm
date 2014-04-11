package App::bif::upgrade;
use strict;
use warnings;
use App::bif::Context;
use Path::Tiny qw/path/;

our $VERSION = '0.1.0_5';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw( $ctx->{directory} );

    my ( $old, $new ) = $db->txn( sub { $db->deploy } );

    if ( $new > $old ) {
        printf( "Database upgraded (v%s-v%s)\n", $old, $new );
    }
    else {
        printf( "Database remains at v%s\n", $new );
    }

    return $ctx->ok('Upgrade');
}

1;
__END__

=head1 NAME

bif-upgrade - upgrade a repository

=head1 VERSION

0.1.0_5 (2014-04-11)

=head1 SYNOPSIS

    bif upgrade [DIRECTORY] [OPTIONS...]

=head1 DESCRIPTION

Upgrade a repository to match the version of the installed B<bif>
software.

As an advanced command, C<upgrade> is only shown in usage messages when
C<--help> is given.

=head1 ARGUMENTS

=over

=item DIRECTORY

Upgrade the repository found in DIRECTORY instead of the current
working repository which is the first F<.bif/> directory found when
searching upwards through the filesystem.

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

