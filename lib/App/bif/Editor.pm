package App::bif::Editor;
use strict;
use warnings;
use Bif::Mo;
use Carp            ();
use File::Which     ();
use Path::Tiny      ();
use Proc::FastSpawn ();

our @CARP_NOT = (__PACKAGE__);

has auto => (
    is      => 'ro',
    default => 1,
);

has txt => ( is => 'rw', );

has encoding => (
    is      => 'ro',
    default => ':utf8',
);

has filename => (
    is      => 'rw',
    default => sub { Path::Tiny->tempfile },
);

has editor => (
    is      => 'ro',
    default => \&_build_editor,
);

has pid => ( is => 'rw', );

sub _build_editor {
    my $self = shift;

    if ( exists $ENV{EDITOR} ) {

        # Explicit editor defined
        return File::Which::which( $ENV{EDITOR} )
          || Carp::croak("editor not found: $ENV{EDITOR}");
    }

    # Otherwise take the first from our own list
    foreach my $editor (qw/sensible-editor vim vi emacs nano/) {
        my $path = File::Which::which($editor);
        return $path if $path;
    }

    Carp::croak("no suitable editor found");
}

sub BUILD {
    my $self = shift;
    $self->edit if $self->auto;
}

sub edit {
    my $self = shift;
    return if $self->pid or !-t STDOUT;

    $self->filename->spew( { binmode => $self->encoding }, $self->txt )
      if $self->txt;

    $self->pid(
        Proc::FastSpawn::spawn(
            $self->editor, [ $self->editor, $self->filename ]
        )
    );

    return;
}

sub wait_child {
    my $self = shift;
    return unless $self->pid;

    waitpid( $self->pid, 0 );
    $self->pid(undef);

    my $res = $?;
    my $err = $!;

    if ( $res == -1 ) {
        Carp::croak sprintf "%s failed to execute: %s", $self->editor, $err;
    }
    elsif ( $res & 127 ) {
        Carp::croak sprintf(
            "%s died with signal %d, %s coredump",
            $self->editor,
            ( $res & 127 ),
            ( ( $res & 128 ) ? 'with' : 'without' )
        );
    }
    elsif ( my $code = $res >> 8 ) {
        Carp::croak sprintf( "%s exited with code %d", $self->editor, $code );
    }
}

sub result {
    my $self = shift;
    return $self->txt unless -t STDOUT;
    $self->wait_child;

    return $self->filename->slurp( { binmode => $self->encoding } );
}

sub DESTROY {
    my $self = shift;
    $self->wait_child;
}

1;

__END__

=head1 NAME

=for bif-doc #perl

App::bif::Editor - run a system (text) editor

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    use App::bif::Editor;

    my $editor = App::bif::Editor->new(txt => $some_text);

    print "You edited the following:\n". $editor->result;

=head1 DESCRIPTION

B<App::bif::Editor> starts a system editor, optionally with text that
you provide, or on a filename you provide, and allows you to retrieve
the result.

This does basically the same thing as L<Proc::InvokeEditor>, however it
has much simpler and less code, has less dependencies, should work on
Win32, defaults to unicode, and more importantly doesn't use system()
so we can still do stuff while the editor is running. For example,
timesheet tracking that is accurate even when the user suspends their
laptop.

As an aide for testing, if F<STDOUT> is not connected to a terminal
then no editor will be started and the C<result> method will return the
C<txt> attribute.

=head1 CONSTRUCTOR

The C<new()> constuctor takes the following arguments.

=over

=item auto

By default the editor is started when the object is created. Set
C<auto> to a false value to inhibit this behaviour.

=item encoding

The Perl IO layer encoding to write and read the file with. Defaults to
':utf8'. Set it to ':raw' to get binary mode.

=item editor

The editor executable to run. If this is not given then the EDITOR
environment variable will be used, and if that is empty then the
following programs will be searched for using L<File::Which>:
sensible-editor, vim, vi, emacs, nano.

=item txt

The contents to write to the file before the editor starts. Note that
this will OVERWRITE the contents of the C<filename> attribute!

=item filename

A L<Path::Tiny> filename to edit. Defaults to a temporary file.

=back

=head1 ATTRIBUTES

=over

=item pid

The process ID of the editor program.

=back

=head1 METHODS

=over

=item edit

Open the editor if it is not running. Can be called safely when the
editor is already running.

=item result

Returns the contents of the C<filename>.

=item wait_child

Wait for the editor process to finish.

=back

=head1 SEE ALSO

L<Proc::FastSpawn>, L<Proc::InvokeEditor>


=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

