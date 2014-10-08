package App::bif::new::plan;
use strict;
use warnings;
use Bif::Mo;
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    $opts->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $opts->{title} ||= prompt( 'Title:', '' )
      || return $self->err( 'TitleRequired', 'title is required' );

    $opts->{message} ||= "New plan $opts->{name}";

    my $provider;
    if ( $opts->{name} =~ s/(.*?):(.*)/$2/ ) {
        $provider = $dbw->xhashref(
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
        my @providers = $dbw->xhashrefs(
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

    $dbw->txn(
        sub {
            my $uid = $self->new_change( message => $opts->{message}, );
            my $id = $dbw->nextval('topics');

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    kind      => 'plan',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_plan',
                values      => {
                    id          => $id,
                    change_id   => $uid,
                    provider_id => $provider->{id},
                    name        => $opts->{name},
                    title       => $opts->{title},
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new plan (%s) $opts->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            printf( "Plan created: %s:%s\n", $provider->{name}, $opts->{name} );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    return $self->ok('NewPlan');
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-new-plan - create a new plan in the repository

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif new plan [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-plan> command creates a new plan of bif hub hosting.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the plan.

=item --message, -m MESSAGE

The creation message, set to "" by default.

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

