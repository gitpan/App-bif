package App::bif::show::hub;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif::show';

sub run {
    my $self   = shift;
    my $opts   = $self->opts;
    my $db     = $self->db;
    my $hub    = $self->get_hub( $opts->{name} );
    my @repos  = $db->get_hub_repos( $hub->{id} );
    my ($bold) = $self->colours('bold');

    my @data;

    push(
        @data,
        $self->header(
            '  ID', $hub->{id},
            $opts->{full} ? $hub->{uuid} : substr( $hub->{uuid}, 1, 8 )
        ),
    );

    foreach my $repo (@repos) {
        push(
            @data,
            $self->header(
                '  Location',
                $repo->{location},
                $repo->{isdefault} ? 'default' : ()
            )
        );
    }

    my $info = $db->xhashref(
        select     => [qw/t.ctime t.ctimetz t.mtime t.mtimetz/],
        from       => 'topics t',
        inner_join => 'changes c',
        on         => 'c.id = t.first_change_id',
        where      => { 't.id' => $hub->{id} },
    );

    $self->start_pager;
    print $self->render_table( 'l  l', [ $bold . 'Hub', $hub->{name} ], \@data,
        1 );

    return $self->ok( 'ShowHub', \@data );
}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show-hub - display a hub's current status

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif show hub NAME [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-hub> command displays a summary of a hub's current
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

=item --uuid, -U

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



