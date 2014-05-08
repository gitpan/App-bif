package App::bif::log::hub;
use strict;
use warnings;
use App::bif::Context;
use App::bif::log;
use locale;

our $VERSION = '0.1.0_20';

sub run {
    my $ctx  = App::bif::Context->new(shift);
    my $db   = $ctx->db;
    my @locs = $db->get_hub_locations( $ctx->uuid2id( $ctx->{alias} ) );

    return $ctx->err( 'HubNotFound', "hub not found: $ctx->{alias}" )
      unless @locs;

    my $hub = shift @locs;

    App::bif::log::init;
    my $dark  = $App::bif::log::dark;
    my $reset = $App::bif::log::reset;

    my $sth = $db->xprepare(
        select => [
            q{strftime('%w',u.mtime,'unixepoch','localtime') AS weekday},
            q{strftime('%Y-%m-%d',u.mtime,'unixepoch','localtime') AS mdate},
            q{strftime('%H:%M:%S',u.mtime,'unixepoch','localtime') AS mtime},
            'u.message',
        ],
        from       => 'hub_updates hu',
        inner_join => 'updates u',
        on         => 'u.id = hu.update_id',
        where      => { 'hu.hub_id' => $hub->{id} },

        #        group_by   => [qw/weekday mdate mtime/],
        order_by => 'u.id DESC',
    );

    $sth->execute;

    $ctx->start_pager;

    my @days = (
        qw/Sunday Monday Tuesday Wednesday Thursday Friday
          Saturday/
    );

    my $first   = $sth->array;
    my $weekday = $first->[0];

    print " $dark$first->[1] ($days[$weekday]) $reset \n";
    print '-' x 80, "\n";
    print " $first->[2]  $first->[3]\n";

    while ( my $n = $sth->array ) {
        if ( $n->[0] != $weekday ) {
            print "\n $dark$n->[1] ($days[ $n->[0] ])$reset\n";
            print '-' x 80, "\n";
        }

        print " $n->[2]  $n->[3]\n";
        $weekday = $n->[0];
    }

    $ctx->end_pager;
    return $ctx->ok('LogHub');
}

1;
__END__

=head1 NAME

bif-log-hub - review the history of a hub

=head1 VERSION

0.1.0_20 (2014-05-08)

=head1 SYNOPSIS

    bif log hub ALIAS [OPTIONS...]

=head1 DESCRIPTION

The C<bif log hub> command displays the history of events in a hub or
the local repository.

=head1 ARGUMENTS & OPTIONS

=over

=item ALIAS

The alias of a hub. Required. Use "local" for obtaining the log of the
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

