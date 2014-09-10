package App::bif::new::plan;
use strict;
use warnings;
use parent 'App::bif::Context';
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;

    $self->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $self->{title} ||= prompt( 'Title:', '' )
      || return $self->err( 'TitleRequired', 'title is required' );

    $self->{message} ||= '';

    my $provider;
    if ( $self->{name} =~ s/(.*?):(.*)/$2/ ) {
        $provider = $db->xhashref(
            select     => [qw/p.id e.name/],
            from       => 'providers p',
            inner_join => 'entities e',
            on         => 'e.id = p.id',
            where      => { 'e.name' => $1 },
        );

        return $self->err( 'ProviderNotFound', 'provider not found: ' . $1 )
          unless $provider;
    }
    else {
        my @providers = $db->xhashrefs(
            select     => [qw/p.id e.name/],
            from       => 'providers p',
            inner_join => 'entities e',
            on         => 'e.id = p.id',
        );

        return $self->err( 'NoProvider', 'a plan needs a provider' )
          unless @providers;

        return $self->err( 'AmbiguousProvider', 'ambiguous provider' )
          if @providers > 1;

        $provider = $providers[0];
    }

    $db->txn(
        sub {
            my $uid = $self->new_update( message => $self->{message}, );
            my $id = $db->nextval('topics');

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    update_id => $uid,
                    kind      => 'plan',
                },
            );

            $db->xdo(
                insert_into => 'func_new_plan',
                values      => {
                    id          => $id,
                    update_id   => $uid,
                    provider_id => $provider->{id},
                    name        => $self->{name},
                    title       => $self->{title},
                },
            );

            $db->xdo(
                insert_into => 'update_deltas',
                values      => {
                    update_id         => $uid,
                    new               => 1,
                    action_format     => "new plan %s ($self->{name})",
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            printf( "Plan created: %s:%s\n", $provider->{name}, $self->{name} );

            # For test scripts
            $self->{id}        = $id;
            $self->{update_id} = $uid;
        }
    );

    return $self->ok('NewPlan');
}

1;
__END__

=head1 NAME

bifhub-new-plan - create a new plan in the repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bifhub new plan [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The C<bifhub new plan> command creates a new plan of bif hub hosting.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the plan.

=item --message, -m MESSAGE

The creation message, set to "" by default.

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

