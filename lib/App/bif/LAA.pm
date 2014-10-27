package App::bif::LAA;
use strict;
use warnings;
use parent 'Log::Any::Adapter::FileScreenBase';

our $VERSION = '0.1.4';

__PACKAGE__->make_logging_methods(
    sub {
        print $_[1] . "\n";
    }
);

1;

__END__

=head1 NAME

=for bif-doc #perl

App::bif::LAA - Simple adapter for logging to current filehandle

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    use Log::Any::Adapter ('+App::bif::LAA');

    # or

    use Log::Any::Adapter;
    ...
    Log::Any::Adapter->set('+App::bif::LAA');

=head1 DESCRIPTION

This is a simple adapter for L<Log::Any> that logs each message to the
currently selected filehandle with a newline appended.  It is basically
the same as L<Log::Any::Adapter::Stdout> but does not explicitly print
to STDOUT.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

