package App::bif::new::repo;
use strict;
use warnings;
use Bif::Mo;
use Bif::DBW;
use Config::Tiny;
use Log::Any '$log';
use Path::Tiny qw/path tempdir/;

our $VERSION = '0.1.4';
extends 'App::bif';

has subref => ( is => 'ro', );

sub run {
    my $self = shift;
    my $opts = $self->opts;

    return $self->err( 'DirExists', 'location exists: ' . $opts->{directory} )
      if -e $opts->{directory};

    $opts->{directory} = path( $opts->{directory} );
    $opts->{directory}->parent->mkpath;

    my $tempdir = tempdir(
        DIR     => $opts->{directory}->parent,
        CLEANUP => !$opts->{debug},
    );
    $log->debug( 'init: tmpdir ' . $tempdir );

    $self->repo($tempdir);

    my $dbw = $self->dbw;

    # On windows at least, an SQLite handle on the database prevents a
    # rename or temp directory removal. Unfortunately, doing the
    # eval/disconnect check below results in the "uncleared implementors
    # data" warning on error. For the moment I would prefer the warning
    # than have the user left with a temporary directory to clean up.

    eval {
        $dbw->txn(
            sub {
                $|++;
                printf "Creating repository: %s", $opts->{directory};

                my ( $old, $new ) = $dbw->deploy;
                print " (v$new)\n";

                $self->subref->($self) if $self->subref;
            }
        );
    };

    if ( my $err = $@ ) {
        $dbw->disconnect;
        Carp::croak $err;
    }
    $dbw->disconnect;

    if ( $opts->{config} ) {
        my $conf = Config::Tiny->new;

        $conf->{'user.alias'}->{ls} =
          'list topics --status open --project-status run';
        $conf->{'user.alias'}->{lss} =
          'list topics --status stalled --project-status run';
        $conf->{'user.alias'}->{lsp} = 'list projects define plan run';
        $conf->{'user.alias'}->{lsi} = 'list identities';

        $conf->write( $tempdir->child('config') );
    }

    # We don't care if this fails as it is just a convenience for being
    # able to run commands inside a repo.
    symlink( '.', $tempdir->child('.bif') ) unless $self->MSWin32;

    $tempdir->move( $opts->{directory} )
      || return $self->err( 'Rename',
        "rename $tempdir $opts->{directory}: $!" );

    # Rebuild the dbw for further commands?
    $self->repo( $opts->{directory} );
    $self->dbw( $self->_build_dbw );

    return $self->ok('NewRepo');
}

1;
__END__

=head1 NAME

=for bif-doc #devadmin

bif-new-repo -  create an empty repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif init DIRECTORY [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-repo> command initialises a new bif repository in
DIRECTORY.  Attempting to initialise an existing repository is
considered an error.

=head1 ARGUMENTS & OPTIONS

=over

=item DIRECTORY

The location of the new repository.

=item --config

Add a default config file to the repository.

=back

The global C<--user-repo> option is ignored by B<bif-new-repo>.

=head1 SEE ALSO

L<bif-init>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

