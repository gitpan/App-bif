package App::bif::update;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self  = shift;
    my $opts  = $self->opts;
    my $info  = $self->get_topic( $self->uuid2id( $opts->{id} ) );
    my $class = "App::bif::update::$info->{kind}";

    if ( eval "require $class" ) {
        $opts->{path} = delete $opts->{id}
          if ( $info->{kind} eq 'project' );

        return $class->can('run')->($self);
    }

    die $@ if $@;

    return $self->err( 'ChangeUnimplemented',
        'cannnot change type: ' . $info->{kind} );
}

1;
__END__

=head1 NAME

=for bif-doc #modify

bif-update - change or comment a topic

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif update ID [STATUS] [OPTIONS...]

=head1 DESCRIPTION

Add a comment to a topic, possibly setting a new status at the same
time. Valid values for a topics's status depend on the projects it is
associated with. The list of valid status for a project can be found
using L<bif-list-status>(1).

=head1 ARGUMENTS

=over

=item ID

A topic ID, a topic ID.UPDATE_ID, or project PATH. Required.

=item STATUS

The new status for the topic. The status cannot be set when commenting
as a reply to another change.

=back

=head1 OPTIONS

=over

=item --title, -t

The new title for the topic.  The title cannot be set when commenting
as a reply to another change.

=item --message, -m

The message describing this issue in detail. If this option is not used
an editor will be invoked.

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

