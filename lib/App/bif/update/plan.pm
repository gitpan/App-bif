package App::bif::update::plan;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_topic( $self->{id} );

    if ( $self->{reply} ) {
        my $uinfo =
          $self->get_change( $self->{reply}, $info->{first_change_id} );
        $self->{parent_uid} = $uinfo->{id};
    }
    else {
        $self->{parent_uid} = $info->{first_change_id};
    }

    $self->{message} ||= $self->prompt_edit( opts => $self );

    my @add;
    foreach my $id ( @{ $self->{add} || [] } ) {
        my $exists = $db->xarrayref(
            select     => 'h.id',
            from       => 'plans pl',
            inner_join => 'providers p',
            on         => 'p.id = pl.provider_id',
            inner_join => 'hosts h',
            on         => {
                'h.provider_id' => \'p.id',
                'h.id'          => $id,
            },
            where => { 'pl.id' => $info->{id} },
        );

        return $self->err( 'HostNotFound', 'host ID not found/valid: %d', $id )
          unless $exists;

        push( @add, $id );
    }

    my @remove;
    foreach my $id ( @{ $self->{remove} || [] } ) {
        my $exists = $db->xarrayref(
            select     => 'h.id',
            from       => 'plans pl',
            inner_join => 'providers p',
            on         => 'p.id = pl.provider_id',
            inner_join => 'hosts h',
            on         => {
                'h.provider_id' => \'p.id',
                'h.id'          => $id,
            },
            where => { 'pl.id' => $info->{id} },
        );
        return $self->err( 'HostNotFound', 'host ID not found/valid: %d', $id )
          unless $exists;
        push( @remove, $id );
    }

    $db->txn(
        sub {
            my $uid = $self->new_change(
                message   => $self->{message},
                parent_id => $self->{parent_uid},
            );

            foreach my $host_id (@add) {
                $db->xdo(
                    insert_into => 'func_change_plan',
                    values      => {
                        change_id  => $uid,
                        id         => $info->{id},
                        add_remove => 1,
                        host_id    => $host_id,
                    },
                );
            }

            foreach my $host_id (@remove) {
                $db->xdo(
                    insert_into => 'func_change_plan',
                    values      => {
                        change_id  => $uid,
                        id         => $info->{id},
                        add_remove => 0,
                        host_id    => $host_id,
                    },
                );
            }

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update plan %s",
                    action_topic_id_1 => $info->{id},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            print "Plan changed: $self->{id}.$uid\n";
        }
    );

    return $self->ok('ChangePlan');
}

1;
__END__

=head1 NAME

bif-update-plan - update or comment an plan

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif update plan NAME [OPTIONS...]

=head1 DESCRIPTION

The "bif update plan" command adds a comment to a plan, possibly adding
or removing hosts.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

An plan name in format [PROVIDER:]NAME, required.

=item --add, -a HOST

Add the HOST in format [PROVIDER:]NAME to the plan. Can be called
multiple times.

=item --remove, -r HOST

Remove the HOST in format [PROVIDER:]NAME from the plan. Can be called
multiple times.

=item --message, -m

The message describing this change in detail.

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

