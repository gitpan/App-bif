package App::bif::show::plan;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif::show';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;
    $opts->{id} = $self->uuid2id( $opts->{id} );

    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhashref(
        select => [
            'pl.id',              'substr(t.uuid,1,8) as uuid',
            'pl.name',            'pl.title',
            'e.name AS provider', 't.ctime',
            't.ctimetz',          't.mtime',
            't.mtimetz',          'c.author',
            'c.email',            'c.message',
        ],
        from       => 'plans pl',
        inner_join => 'topics t',
        on         => 't.id = pl.id',
        inner_join => 'providers p',
        on         => 'p.id = pl.provider_id',
        inner_join => 'entities e',
        on         => 'e.id = p.id',
        inner_join => 'changes c',
        on         => 'c.id = t.first_change_id',
        where      => { 'pl.id' => $opts->{id} },
    );

    return $self->err( 'PlanNotFound', "plan not found: $opts->{id}" )
      unless $ref;

    my ($bold) = $self->colours('bold');

    push( @data,
        $self->header( '  UUID',     $ref->{uuid} ),
        $self->header( '  Name',     $ref->{name} ),
        $self->header( '  Provider', $ref->{provider} ),
    );

    push( @data, $self->header( '  Contact', $ref->{contact} ), )
      if $ref->{other_contact};

    push(
        @data,
        $self->header(
            '  Updated', $self->ago( $ref->{mtime}, $ref->{mtimetz} )
        ),
    );

    my @methods = $db->xhashrefs(
        select     => [ 'h.name', ],
        from       => 'plan_hosts ph',
        inner_join => 'hosts h',
        on         => 'h.id = ph.host_id',
        where      => { 'ph.plan_id' => $opts->{id} },
        order_by   => [qw/ h.name /],
    );

    push( @data, $self->header( '  Host', $_->{name}, ) ) for @methods;

    $self->start_pager;
    print $self->render_table( 'l  l', [ $bold . 'Plan', $ref->{title} ],
        \@data, 1 );

    return $self->ok( 'ShowPlan', \@data );
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-show-plan - display a plan's current status

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif show plan ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-plan> command displays the characteristics of an plan.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An plan ID. Required.

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

