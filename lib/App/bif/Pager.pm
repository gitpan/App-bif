package App::bif::Pager;
use strict;
use warnings;
use Bif::Mo;
use Carp ();
use File::Which;

our @CARP_NOT = (__PACKAGE__);

has encoding => (
    is      => 'ro',
    default => ':utf8',
);

has pager => (
    is      => 'ro',
    default => \&_build_pager,
);

has fh => ( is => 'rw' );

has pid => ( is => 'rw' );

has orig_fh => (
    is      => 'ro',
    default => sub { select },
    lazy    => 0,
);

sub _build_pager {
    my $self = shift;

    if ( exists $ENV{PAGER} ) {

        # Explicit pager defined
        my ( $pager, @options ) = split ' ', $ENV{PAGER};
        my $path = File::Which::which($pager);
        Carp::croak("pager not found: $pager") unless $path;
        return join( ' ', $path, @options );
    }

    # Otherwise take the first from our own list
    foreach my $pager (qw/pager less most w3m lv pg more/) {
        my $path = File::Which::which($pager);
        return $path if $path;
    }

    Carp::croak("no suitable pager found");
}

sub BUILD {
    my $self  = shift;
    my $pager = $self->pager;

    my $pid = open( my $fh, '|-', $pager )
      or Carp::croak "Could not pipe to PAGER ('$pager'): $!\n";

    binmode( $fh, $self->encoding );
    select $fh;
    $| = 1;

    $self->fh($fh);
    $self->pid($pid);

    return;
}

sub close {
    my $self = shift;
    my $fh = $self->fh || return;
    select $self->orig_fh;
    CORE::close($fh);
    $self->fh(undef);
}

sub DESTROY {
    my $self = shift;
    $self->close;
}

1;

__END__

=head1 NAME

=for bif-doc #perl

App::bif::Pager - pipe output to a system (text) pager

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    use App::bif::Pager;

    my $pager = App::bif::Pager->new(encoding => ':utf8');
    print "This text goes to a pager\n";

    undef $pager;
    print "This text goes to STDOUT\n";

=head1 DESCRIPTION

B<App::bif::Pager> opens a connection to a system pager and makes it
the default filehandle so that by default any print statements are sent
there.

When the pager object goes out of scope the previously selected
filehandle is selected again.

=head1 CONSTRUCTOR

The new() constuctor takes the following arguments:

=over

=item encoding

The Perl IO layer encoding to set (with binmode) after the pager has
been opened. This defaults to ':utf8'.

=item pager

The pager executable to run. If this is not given then the PAGER
environment variable will be used, and if that is empty then the
following programs will be searched for using L<File::Which>: pager,
less, most, w3m, lv, pg, more.

=back

=head1 ATTRIBUTES

=over

=item fh

The underlying filehandle of the pager.

=item pid

The process ID of the pager program (only set on UNIX systems)

=item orig_fh

The original filehandle that was selected before the pager was started.

=back

=head1 SEE ALSO

L<IO::Pager> - does something similar by mucking directly with STDOUT
in a way that breaks fork/exec, and I couldn't for the life of me
decipher the code style enough to fix it.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

