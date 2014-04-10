package App::bif::sql;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_4';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db = $ctx->{write} ? $ctx->dbw : $ctx->db;

    if ( !$ctx->{statement} ) {
        local $/;
        $ctx->{statement} = <STDIN>;
    }

    if ( $ctx->{statement} =~ m/^(select)|(pragma)|(explain)/i ) {
        my $sth = $db->prepare( $ctx->{statement} );
        $sth->execute(@_);

        my $header = join( ', ', @{ $sth->{NAME} } );
        print $header, "\n", ( '-' x length $header ), "\n";
        print DBI::neat_list($_) . "\n" for @{ $sth->fetchall_arrayref };
    }
    else {
        print $db->do( $ctx->{statement} ) . "\n";
    }

    return 'BifSQL';
}

1;
__END__

=head1 NAME

bif-sql -  run an SQL command against the database

=head1 VERSION

0.1.0_4 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif sql [STATEMENT...]  [OPTIONS...]

=head1 DESCRIPTION

Run an SQL statement directly against the database. If the statement is
not given on the command line it will be read from I<stdin>.

If the statement begins with "select" or "pragma" the results of the
statement will be fetched and displayed. Otherwise the return value of
the statement (DBI "do" method) will be printed.

By default a read-only handle for the database is used. Note that
"pragma" statements would therefore require the C<--write> flag to
succeed, even if they are only returning data.

=head1 ARGUMENTS

=over

=item STATEMENT

The SQL statement text to execute. You will possibly want to use single
quotes around this argument (or escape shell characters like "*") to
prevent unwanted shell expansion messing with your query.

=back

=head1 OPTIONS

=over

=item --write, -w

Run statement with a writeable database handle (default is read-only).

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

