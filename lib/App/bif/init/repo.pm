package App::bif::init::repo;
use strict;
use warnings;
use parent 'App::bif::Context';
use Bif::DBW;
use Config::Tiny;
use Log::Any '$log';
use Path::Tiny qw/path tempdir/;

our $VERSION = '0.1.0_27';

sub run {
    my $self   = __PACKAGE__->new(shift);
    my $subref = shift;

    return $self->err( 'DirExists', 'location exists: ' . $self->{directory} )
      if -e $self->{directory};

    $self->{directory} = path( $self->{directory} );
    $self->{directory}->parent->mkpath;
    $self->{directory} = $self->{directory}->realpath;

    my $tempdir = tempdir(
        DIR     => $self->{directory}->parent,
        CLEANUP => !$self->{debug},
    );
    $log->debug( 'init: tmpdir ' . $tempdir );

    $self->{_bif_repo} = $tempdir;
    my $dbw = $self->dbw;

    $dbw->txn(
        sub {
            $|++;
            printf "Initialising repository: %s", $self->{directory};

            my ( $old, $new ) = $dbw->deploy;
            print " (v$new)\n";

            $subref->(%$self) if $subref;
        }
    );

    if ( $self->{config} ) {
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

    $tempdir->move( $self->{directory} )
      || return $self->err( 'Rename',
        "rename $tempdir $self->{directory}: $!" );

    return $self->ok('InitRepo');
}

1;
__END__

=head1 NAME

bif-init-repo -  create new bif repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif init DIRECTORY [OPTIONS...]

=head1 DESCRIPTION

The B<bif-init-repo> command initialises a new bif repository in
DIRECTORY.  Attempting to initialise an existing repository is
considered an error.

=head1 ARGUMENTS & OPTIONS

=over

=item DIRECTORY

The location of the new repository.

=item --config

Add a default config file to the repository.

=back

The global C<--user-repo> option is ignored by B<bif-init-repo>.

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

