package App::bif::help;
use strict;
use warnings;
use App::bif::Util;
use Pod::Perldoc;

our $VERSION = '0.1.0';

sub run {
    my $opts = bif_init(shift);

    if ( $opts->{command} ) {
        @ARGV = ( join( '/', 'App', 'bif', @{ $opts->{command} } ) );

        bif_err( 'CommandNotFound', "unknown COMMAND: @{$opts->{command}}" )
          unless eval { require $ARGV[0] . '.pm' };
    }
    else {
        @ARGV = ($0);
    }

    # TODO: This calls exit directly... how to patch around that?
    Pod::Perldoc->run();

    # Never reached
    return bif_ok('Help');
}

1;
__END__

=head1 NAME

bif-help -  display help information about bif

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif help [COMMAND...] [OPTIONS...]

=head1 DESCRIPTION

Displays the reference documentation for bif or a particular bif
COMMAND.

=head1 ARGUMENTS

=over

=item COMMAND

A valid bif command.

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

