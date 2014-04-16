package App::bif::init;
use strict;
use warnings;
use App::bif::Context;
use Config::Tiny;
use Bif::DB::RW;
use Log::Any '$log';
use Path::Tiny qw/path cwd tempdir/;

our $VERSION = '0.1.0_9';

sub run {
    my $ctx = App::bif::Context->new(shift);

    $ctx->{directory} = path( $ctx->{directory} || cwd )->absolute;

    my $bifdir;
    if ( $ctx->{bare} ) {
        $bifdir = $ctx->{directory};
    }
    else {
        $bifdir = $ctx->{directory}->child('.bif');
    }

    return $ctx->err( 'DirExists', 'directory exists: ' . $bifdir )
      if -e $bifdir;

    $bifdir->parent->mkpath;

    my $tempdir = tempdir( DIR => $bifdir->parent, CLEANUP => !$ctx->{debug} );
    $log->debug( 'init: tmpdir ' . $tempdir );

    my $config = Config::Tiny->new;
    $config->write( $tempdir->child('config') );

    my $dbfile = $tempdir->child('db.sqlite3');
    my $dbw    = Bif::DB::RW->connect( 'dbi:SQLite:dbname=' . $dbfile,
        undef, undef, undef, $ctx->{debug} );

    $log->debug( 'init: SQLite version: ' . $dbw->{sqlite_version} );

    my ( $old, $new );
    $dbw->txn(
        sub {
            ( $old, $new ) = $dbw->deploy;

            my $uid = $dbw->nextval('updates');
            $dbw->xdo(
                insert_into => 'updates',
                values      => {
                    author  => $ctx->{user}->{name},
                    email   => $ctx->{user}->{email},
                    message => 'init '
                      . $ctx->{directory}
                      . ( $ctx->{bare} ? ' --bare' : '' ),
                    id => $uid,
                },
            );

            my $rid = $dbw->nextval('topics');
            $dbw->xdo(
                insert_into => 'func_new_repo',
                values      => {
                    id        => $rid,
                    update_id => $uid,
                    local     => 1,
                    alias     => 'local',
                },
            );

            my $rlid = $dbw->nextval('topics');
            $dbw->xdo(
                insert_into => 'func_new_repo_location',
                values      => {
                    id        => $rlid,
                    repo_id   => $rid,
                    update_id => $uid,
                    location  => $bifdir,
                },
            );

            $dbw->xdo(
                insert_into => 'repo_updates',
                values      => {
                    update_id           => $uid,
                    repo_id             => $rid,
                    default_location_id => $rlid,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    symlink( '.', $tempdir->child('.bif') ) if $ctx->{bare};

    rename( $tempdir, $bifdir )
      || return $ctx->err( 'Rename', "rename $tempdir $bifdir: $!" );

    printf "Database initialised (v%s) in %s/\n", $new, $bifdir;

    return $ctx->ok('Init');
}

1;
__END__

=head1 NAME

bif-init -  create new bif repository

=head1 VERSION

0.1.0_9 (2014-04-16)

=head1 SYNOPSIS

    bif init [DIRECTORY] [OPTIONS...]

=head1 DESCRIPTION

The C<bif init> command initializes a new bif repository. The
repository is usually a directory named F<.bif> containing the
following files:

=over

=item F<config>:

Configuration information in INI format

=item F<db.sqlite3>:

repository data in an SQLite database

=back

By default F<.bif> is created underneath the current working directory.

    bif init

You can initialize a repository under a different location by giving a
DIRECTORY as the first argument, which will be created if it doesn't
already exist.

    bif init elsewhere

If you are creating a repository for use as a hub then the C<--bare>
option can be used to skip the creation of the F<.bif> directory.

    bif init my-hub --bare

Attempting to initialize an existing repository is considered an error.

=head1 ARGUMENTS & OPTIONS

=over

=item DIRECTORY

The parent location of the respository directory. Defaults to the
current working directory (F<.> or F<$PWD>).

=item --bare

Initialize the repository in F<DIRECTORY> directly instead of
F<DIRECTORY/.bif>.

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

