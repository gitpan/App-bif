package App::bif::reply;
use strict;
use warnings;
use App::bif::Util;
require App::bif::update;

our $VERSION = '0.1.0';

sub run {
    my $opts   = bif_init(shift);
    my $config = bif_conf;
    my $db     = bif_dbw;

    my $info = $db->get_update( $opts->{update_id} )
      || bif_err( 'UpdateNotFound', 'update not found: ' . $opts->{update_id} );

    my $func = App::bif::update->can( '_update_' . $info->{kind} )
      || bif_err(
        'Reply' . ucfirst( $info->{kind} ) . 'Unimplemented',
        'cannnot reply to type: ' . $info->{kind}
      );

    $opts->{lang}   ||= 'en';
    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

    # TODO calculate parent_update_id

    return $func->( $opts, $db, $info );
}

1;
__END__

=head1 NAME

bif-reply - reply to a previous update or comment

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif reply UPDATE_ID [OPTIONS...]

=head1 DESCRIPTION

Add a comment in reply to an existing update or comment.

=head1 ARGUMENTS

=over

=item UPDATE_ID

A topic ID.UPDATE_ID. Required.

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

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

