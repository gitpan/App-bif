package App::bif::init;
use strict;
use warnings;
use App::bif::Util;
use Config::Tiny;
use Log::Any '$log';
use Path::Tiny qw/path cwd tempdir/;

our $VERSION = '0.1.0';

sub run {
    my $opts   = bif_init(shift);
    my $parent = path( $opts->{directory} || cwd )->absolute;
    my $bifdir = $parent->child('.bif');

    bif_err( 'DirExists', 'directory exists: ' . $bifdir ) if -e $bifdir;

    mkdir $parent;    # don't care if this already exists
    my $tempdir = tempdir( DIR => $parent, CLEANUP => !$opts->{debug} );
    $log->debug( 'working in ' . $tempdir );

    my $config = Config::Tiny->new;
    $config->{alias}->{lt}  = 'list topics --status open';
    $config->{alias}->{lts} = 'list topics --status stalled';
    $config->{alias}->{ltc} = 'list projects --status closed';
    $config->{alias}->{lp}  = 'list projects --status run';
    $config->write( $tempdir->child('config') );

    my $db = bif_dbw($tempdir);

    require DBIx::ThinSQL::SQLite;
    DBIx::ThinSQL::SQLite::create_sqlite_sequence($db);

    require DBIx::ThinSQL::Deploy;
    my ( $old, $version );

    if ( defined &static::find ) {
        $db->txn(
            sub {
                my $src =
                  'auto/share/dist/App-bif/' . $db->{Driver}->{Name} . '.sql';

                my $sql = static::find($src)
                  or bif_err( 'DBUnsupported',
                    'unsupported database type: ' . $db->{Driver}->{Name} );

                ( $old, $version ) = $db->deploy_sql($sql);
            }
        );
    }
    else {
        require File::ShareDir;

        my $share_dir = $main::BIF_SHARE_DIR
          || File::ShareDir::dist_dir('App-bif');

        my $deploy_dir = path( $share_dir, $db->{Driver}->{Name} );

        if ( !-d $deploy_dir ) {
            bif_err( 'DBUnsupported',
                'unsupported database type: ' . $db->{Driver}->{Name} );
        }

        $db->txn(
            sub {
                DBIx::ThinSQL::SQLite::create_sqlite_sequence($db);
                ( $old, $version ) = $db->deploy_dir($deploy_dir);
            }
        );

    }

    rename( $tempdir, $bifdir )
      || bif_err( 'Rename', "rename $tempdir $bifdir: $!" );

    printf "Database initialised (v%s) in %s/\n", $version, $bifdir;

    # Need call bif_dbw again because $tempdir has disappeared
    return bif_dbw($bifdir);
}

1;
__END__

=head1 NAME

bif-init -  create new bif repository

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif init [DIRECTORY] [OPTIONS...]

=head1 DESCRIPTION

This command creates an empty bif repository - basically a .bif
directory with an SQLite database, a configuration file and maybe some
alias files.

Running bif init where a repository already exists results in an error.

=head1 ARGUMENTS

=over

=item DIRECTORY

Use DIRECTORY as the start location for the repository instead of the
current working directory (C<$PWD>).

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

