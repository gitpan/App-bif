package App::bif::show::plan;
use strict;
use warnings;
use parent 'App::bif::show';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    $self->{id} = $self->uuid2id( $self->{id} );

    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhashref(
        select => [
            'pl.id',              'substr(t.uuid,1,8) as uuid',
            'pl.name',            'pl.title',
            'e.name AS provider', 't.ctime',
            't.ctimetz',          't.mtime',
            't.mtimetz',          'u.author',
            'u.email',            'u.message',
        ],
        from       => 'plans pl',
        inner_join => 'topics t',
        on         => 't.id = pl.id',
        inner_join => 'providers p',
        on         => 'p.id = pl.provider_id',
        inner_join => 'entities e',
        on         => 'e.id = p.id',
        inner_join => 'updates u',
        on         => 'u.id = t.first_update_id',
        where      => { 'pl.id' => $self->{id} },
    );

    return $self->err( 'PlanNotFound', "plan not found: $self->{id}" )
      unless $ref;

    $self->init;
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
        where      => { 'ph.plan_id' => $self->{id} },
        order_by   => [qw/ h.name /],
    );

    push( @data, $self->header( '  Host', $_->{name}, ) ) for @methods;

    $self->start_pager;
    print $self->render_table( 'l  l',
        $self->header( $bold . 'Plan', $bold . $ref->{title} ), \@data );
    $self->end_pager;

    return $self->ok( 'ShowPlan', \@data );
}

1;
__END__

=head1 NAME

bifhub-show-plan - display a plan's current status

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bifhub show plan ID [OPTIONS...]

=head1 DESCRIPTION

The C<bifhub show plan> command displays the characteristics of an
plan.

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

L<bifhub>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

