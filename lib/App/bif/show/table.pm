package App::bif::show::table;
use strict;
use warnings;
use Bif::Mo;
use DBIx::ThinSQL qw/sq/;

our $VERSION = '0.1.4';
extends 'App::bif::show';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    my $sql = $db->xval(
        select => 'sql',
        from   => 'sqlite_master',
        where  => { tbl_name => $opts->{name}, type => 'table' },
    );

    return $self->err( 'TableNotFound', 'table not found: %s', $opts->{name} )
      unless $sql;

    $self->start_pager;
    print $sql, "\n";

    return $self->ok('ShowTable') unless $opts->{full};

    my @rest = $db->xvals(
        select => 'sql',
        from   => sq(
            select => [qw/name sql/],
            from   => 'sqlite_master',
            where  => {
                tbl_name        => $opts->{name},
                type            => [qw/index trigger/],
                'name not like' => 'sqlite_%',
            },
            order_by => 'name',
        ),
    );

    print "\n", join( "\n\n", @rest ), "\n";
    return $self->ok('ShowFullTable');
}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show-table - display a table's SQL schema

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif show table NAME [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-table> command displays the SQL schema of a table in a
repository.

    bif show table projects
    # CREATE TABLE topics (
    #     id INT NOT NULL PRIMARY KEY,
    #     uuid char(40) NOT NULL UNIQUE,
    #     first_change_id INTEGER NOT NULL,
    #     last_change_id INTEGER NOT NULL,
    #     kind VARCHAR NOT NULL,
    #     ctime INTEGER NOT NULL,
    #     ctimetz INTEGER NOT NULL,
    #     mtime INTEGER NOT NULL,
    #     mtimetz INTEGER NOT NULL,
    #     lang VARCHAR(8) NOT NULL DEFAULT 'en',
    #     hash VARCHAR,
    #     delta_id INTEGER NOT NULL DEFAULT (nextval('deltas')),
    #     num_changes INTEGER,
    #     FOREIGN KEY(first_change_id) REFERENCES changes(id) ON DELETE CASCADE,
    #     FOREIGN KEY(last_change_id) REFERENCES changes(id) ON DELETE NO ACTION
    # )

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

A table name. Required.

=item --full, -f

Display indexes and triggers as well as the table definition.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.



