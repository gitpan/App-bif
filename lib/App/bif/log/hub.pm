package App::bif::log::hub;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::log';
use locale;

our $VERSION = '0.1.0_27';

sub run {
    my $self  = __PACKAGE__->new(shift);
    my $db    = $self->db;
    my ($hub) = $self->get_hub( $self->{name} );
    my @locs  = $db->get_hub_repos( $hub->{id} );

    $self->init;
    my ( $dark, $reset ) = $self->colours(qw/dark reset/);

    my $sth = $db->xprepare(
        select => [
            q{strftime('%w',u.mtime,'unixepoch','localtime') AS weekday},
            q{strftime('%Y-%m-%d',u.mtime,'unixepoch','localtime') AS mdate},
            q{strftime('%H:%M:%S',u.mtime,'unixepoch','localtime') AS mtime},
            'u.action',
        ],
        from       => 'hub_deltas hd',
        inner_join => 'updates u',
        on         => 'u.id = hd.update_id',
        where      => { 'hd.hub_id' => $hub->{id} },

        #        group_by   => [qw/weekday mdate mtime/],
        order_by => 'u.id DESC',
    );

    $sth->execute;

    $self->start_pager;

    my @days = (
        qw/Sunday Monday Tuesday Wednesday Thursday Friday
          Saturday/
    );

    my $first   = $sth->arrayref;
    my $weekday = $first->[0];

    print " $dark$first->[1] ($days[$weekday]) $reset \n";
    print '-' x 80, "\n";
    print " $first->[2]  $first->[3]\n";

    while ( my $n = $sth->arrayref ) {
        if ( $n->[0] != $weekday ) {
            print "\n $dark$n->[1] ($days[ $n->[0] ])$reset\n";
            print '-' x 80, "\n";
        }

        print " $n->[2]  $n->[3]\n";
        $weekday = $n->[0];
    }

    $self->end_pager;
    return $self->ok('LogHub');
}

1;
__END__

=head1 NAME

bif-log-hub - review the history of a hub

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log hub NAME [OPTIONS...]

=head1 DESCRIPTION

The C<bif log hub> command displays the history of events in a hub or
the local repository.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of a hub. Required. Use "local" for obtaining the log of the
current repository.

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

