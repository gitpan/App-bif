package App::bif::upgrade;
use strict;
use warnings;
use App::bif::Util;
use Path::Tiny qw/path/;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_dbw( $opts->{directory} );

    require File::ShareDir;
    my $share_dir = $main::BIF_SHARE_DIR
      || File::ShareDir::dist_dir('App-bif');

    my $deploy_dir = path( $share_dir, $db->{Driver}->{Name} );

    if ( !-d $deploy_dir ) {
        bif_err( 'DBUnsupported',
            'unsupported database type: ' . $db->{Driver}->{Name} );
    }

    require DBIx::ThinSQL::Deploy;

    my ( $old, $new ) = $db->txn(
        sub {
            my ( $old, $new ) = $db->deploy_dir($deploy_dir);

            bif_err( 'NotInitialized',
                'last update id was zero; repo not initialized' )
              unless $old;

            if ( $new < $old ) {
                bif_err( 'DBUpgradeBackward',
                    "Database TRAVELLED BACKWARD! (v%s-v%s)\n",
                    $old, $new );
            }

            return $old, $new;
        }
    );

    if ( $new > $old ) {
        printf( "Database upgraded (v%s-v%s)\n", $old, $new );
    }
    else {
        printf( "Database remains at v%s\n", $new );
    }
    return [ $new, $old ];

}

1;
__END__

=head1 NAME

bif-upgrade - upgrade a repository

=head1 VERSION

0.1.0 (yyyy-mm-dd)

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

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

