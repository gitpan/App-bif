package App::bif::reply;
use strict;
use warnings;
use App::bif::Context;
require App::bif::update;

our $VERSION = '0.1.0_25';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    my $info = $db->get_update( $ctx->{'id.uid'} )
      || return $ctx->err( 'UpdateNotFound',
        'update not found: ' . $ctx->{'id.uid'} );

    my $func = App::bif::update->can( '_update_' . $info->{kind} )
      || return $ctx->err(
        'Reply' . ucfirst( $info->{kind} ) . 'Unimplemented',
        'cannnot reply to type: ' . $info->{kind}
      );

    $ctx->{lang} ||= 'en';

    # TODO calculate parent_update_id

    return $func->( $ctx, $db, $info );
}

1;
__END__

=head1 NAME

bif-reply - reply to a previous update or comment

=head1 VERSION

0.1.0_25 (2014-06-14)

=head1 SYNOPSIS

    bif reply ID.UID [OPTIONS...]

=head1 DESCRIPTION

Add a comment in reply to an existing update or comment.

=head1 ARGUMENTS

=over

=item ID.UID

A topic ID plus update ID. Required.

=back

=head1 OPTIONS

=over

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

