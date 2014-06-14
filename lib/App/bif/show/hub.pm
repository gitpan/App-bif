package App::bif::show::hub;
use strict;
use warnings;
use App::bif::Context;
use App::bif::show;

our $VERSION = '0.1.0_25';

my $yellow = '';

sub run {
    my $ctx  = App::bif::Context->new(shift);
    my $db   = $ctx->db;
    my @locs = $db->get_hub_repos( $ctx->uuid2id( $ctx->{name} ) );

    return $ctx->err( 'HubNotFound', "hub not found: $ctx->{name}" )
      unless @locs;

    my $hub = shift @locs;

    App::bif::show::_init;

    my @data;

    push(
        @data,
        App::bif::show::_header(
            $yellow . 'Hub',
            $yellow . $hub->{name}
        ),

        App::bif::show::_header(
            '  ID', $hub->{id},
            $ctx->{full} ? $hub->{uuid} : substr( $hub->{uuid}, 1, 8 )
        ),
        App::bif::show::_header( '  Location', $hub->{location}, 'default' ),
    );

    foreach my $next (@locs) {
        push( @data,
            App::bif::show::_header( '  Location', $next->{location} ) );
    }

    my $info = $db->xhash(
        select     => [qw/t.ctime t.ctimetz t.mtime t.mtimetz/],
        from       => 'topics t',
        inner_join => 'updates u',
        on         => 'u.id = t.first_update_id',
        where      => { 't.id' => $hub->{id} },
    );

    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    $ctx->end_pager;

    return $ctx->ok( 'ShowHub', \@data );
}

1;
__END__

=head1 NAME

bif-show-hub - display a hub's current status

=head1 VERSION

0.1.0_25 (2014-06-14)

=head1 SYNOPSIS

    bif show hub NAME [OPTIONS...]

=head1 DESCRIPTION

The C<bif show hub> command displays a summary of a hub's current
status.

    bif show hub local
    # Hub:       local                            
    # ID:        1 <2bc47651>                     
    # Location:  /home/mark/src/bif/.bif <default>

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

A hub name or location. Required. You can use "-" to show the status of
the current repository.

=item --full, -f

Display a more verbose version of the current status.

=item --uuid, -u

Lookup the topic using ID as a UUID string instead of a topic integer.

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



