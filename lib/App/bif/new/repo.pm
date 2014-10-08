package App::bif::new::repo;
use strict;
use warnings;
use Bif::Mo;
use Bif::DBW;
use Config::Tiny;
use Log::Any '$log';
use Path::Tiny qw/path tempdir/;

our $VERSION = '0.1.2';
extends 'App::bif';

has subref => ( is => 'ro', );

sub run {
    my $self = shift;
    my $opts = $self->opts;

    return $self->err( 'DirExists', 'location exists: ' . $opts->{directory} )
      if -e $opts->{directory};

    $opts->{directory} = path( $opts->{directory} );
    $opts->{directory}->parent->mkpath;
    $opts->{directory} = $opts->{directory}->realpath;

    my $tempdir = tempdir(
        DIR     => $opts->{directory}->parent,
        CLEANUP => !$opts->{debug},
    );
    $log->debug( 'init: tmpdir ' . $tempdir );

    $self->repo($tempdir);

    my $dbw = $self->dbw;

    $dbw->txn(
        sub {
            $|++;
            printf "Creating repository: %s", $opts->{directory};

            my ( $old, $new ) = $dbw->deploy;
            print " (v$new)\n";

            $self->subref->($dbw) if $self->subref;
        }
    );

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
    symlink( '.', $tempdir->child('.bif') );

    $tempdir->move( $opts->{directory} )
      || return $self->err( 'Rename',
        "rename $tempdir $opts->{directory}: $!" );

    return $self->ok('NewRepo');
}

1;
__END__

=head1 NAME

=for bif-doc #admin

bif-new-repo -  create an empty repository

=head1 VERSION

0.1.2 (2014-10-08)

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

