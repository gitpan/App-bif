package App::bif::sql;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_26';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db;

    if ( $ctx->{user} ) {
        $db = $ctx->{write} ? $ctx->user_dbw : $ctx->user_db;
    }
    else {
        $db = $ctx->{write} ? $ctx->dbw : $ctx->db;
    }

    if ( !$ctx->{statement} ) {
        local $/;
        $ctx->{statement} = <STDIN>;
    }

    if ( $ctx->{statement} =~ m/^(select)|(pragma)|(explain)/i ) {
        my $sth = $db->prepare( $ctx->{statement} );
        $sth->execute(@_);

        if ( $ctx->{noprint} ) {
            return $sth->fetchall_arrayref;
        }

        my $header = ' '
          . ( join '  ', map { $_ =~ m/.id$/ ? 'r' : 'l' } @{ $sth->{NAME} } )
          . ' ';

        my $data = $sth->fetchall_arrayref;
        foreach my $r (@$data) {
            foreach ( 0 .. $#$r ) {
                $r->[$_] = 'NULL' unless defined $r->[$_];
            }
        }

        $ctx->start_pager;

        print $ctx->render_table( $header, $sth->{NAME}, $data );

        $ctx->end_pager;

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

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif sql [STATEMENT...] [OPTIONS...]

=head1 DESCRIPTION

The C<bif sql> command runs an SQL statement directly against the
database of the current bif repository.

    #!sh
    bif sql "select id,message from updates"

If C<STATEMENT> is not given on the command line it will be read from
I<stdin>.  If the statement begins with "select", "pragma" or "explain"
the results of the statement will be fetched and displayed. Otherwise
the return value of the statement (DBI "do" method) will be printed.

By default a read-only handle for the database is used. Note that
"pragma" statements would therefore require the C<--write> flag to
succeed, even if they are only returning data.

=head1 ARGUMENTS & OPTIONS

=over

=item STATEMENT

The SQL statement text to execute. You will possibly want to use single
quotes around this argument (or escape shell characters like "*") to
prevent unwanted shell expansion messing with your query.

=item --noprint

Do not print results but return them to the calling subroutine as a
Perl data structure.  This option is only useful for internal test
scripts.

=item --user, -u

Run the statement against the user identity database instead of against
the current repository database.

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

