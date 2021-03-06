package App::bif::sql;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db;

    if ( $opts->{user} ) {
        $db = $opts->{write} ? $self->user_dbw : $self->user_db;
    }
    else {
        $db = $opts->{write} ? $self->dbw : $self->db;
    }

    if ( !$opts->{statement} ) {
        local $/;
        $opts->{statement} = <STDIN>;
    }

    if ( $opts->{statement} =~ m/^(select)|(pragma)|(explain)/i ) {
        my $sth = $db->prepare( $opts->{statement} );
        $sth->execute(@_);

        if ( $opts->{noprint} ) {
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

        $self->start_pager;

        print $self->render_table( $header, $sth->{NAME}, $data );

    }
    else {
        print $db->do( $opts->{statement} ) . "\n";
    }

    return 'BifSQL';
}

1;
__END__

=head1 NAME

=for bif-doc #devadmin

bif-sql -  run an SQL command against the database

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif sql [STATEMENT...] [OPTIONS...]

=head1 DESCRIPTION

The C<bif sql> command runs an SQL statement directly against the
database of the current bif repository.

=for bifcode #!sh

    bif sql "select id,message from changes"

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

=item --user, -U

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

