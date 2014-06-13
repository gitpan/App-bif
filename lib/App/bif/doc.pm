package App::bif::doc;
use strict;
use warnings;
use App::bif::Context;
use Pod::Perldoc;
use Pod::Simple::Text;

our $VERSION = '0.1.0_24';

sub run {
    my $ctx = App::bif::Context->new(shift);

    if ( $ctx->{command} ) {
        @ARGV = ( join( '/', 'App', 'bif', @{ $ctx->{command} } ) );

        return $ctx->err( 'CommandNotFound',
            qq{no help for "@{$ctx->{command}}"} )
          unless eval { require $ARGV[0] . '.pm' };
    }
    elsif ( defined &static::find ) {
        $ctx->start_pager;
        my $parser = Pod::Simple::Text->new;
        $parser->parse_string_document( static::find('!boot') );
        $ctx->end_pager;
        return $ctx->ok('Help');
    }
    else {
        @ARGV = ($0);
    }

    # TODO: This calls exit directly... how to patch around that?
    Pod::Perldoc->run();

    # Never reached
    return $ctx->ok('Help');
}

1;
__END__

=head1 NAME

bif-doc -  display help information about bif

=head1 VERSION

0.1.0_24 (2014-06-13)

=head1 SYNOPSIS

    bif doc [COMMAND...] [OPTIONS...]

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

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

