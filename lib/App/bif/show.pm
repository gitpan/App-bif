package App::bif::show;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;

    if ( $opts->{id} eq 'VERSION' ) {
        require App::bif::Build;
        print "version: $App::bif::Build::VERSION\n"
          . "date:    $App::bif::Build::DATE\n"
          . "commit:  $App::bif::Build::COMMIT\n";
        print "bin:     $0\n" . "lib:     $App::bif::Build::FILE\n"
          unless defined &static::find;
        return $self->ok('ShowVersion');
    }

    my $info  = $self->get_topic( $self->uuid2id( $opts->{id} ) );
    my $class = "App::bif::show::$info->{kind}";

    if ( eval "require $class" ) {
        $opts->{path} = delete $opts->{id}
          if ( $info->{kind} eq 'project' );

        return $class->can('run')->($self);
    }

    die $@ if $@;

    return $self->err( 'ShowUnimplemented',
        'cannnot show type: ' . $info->{kind} );
}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show - display a topic's current status

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif show ITEM ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show> command displays a summary of a topic's current status.
The output varies depending on the type of topic.

When the uppercase string "VERSION" is given as the ID then this
command will print the bif version string plus the Git branch and Git
commit from which bif was built.

=head1 ARGUMENTS

=over

=item ITEM

The type of topic. As a shortcut if ITEM is an integer then the kind of
topic will be looked up and the appropriate C<bif-show-*> command will
be called.

=item ID

A topic ID or a project PATH. Required.

=back

=head1 OPTIONS

=over

=item --full, -f

Display a more verbose version of the current status.

=item --uuid, -U

Lookup the topic using ID as a UUID string instead of a topic integer.

=back

=head1 SEE ALSO

L<bif>(1), L<App::bif::Build>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

