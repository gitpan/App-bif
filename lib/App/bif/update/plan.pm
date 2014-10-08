package App::bif::update::plan;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;
    my $info = $self->get_topic( $opts->{id} );

    if ( $opts->{reply} ) {
        my $uinfo =
          $self->get_change( $opts->{reply}, $info->{first_change_id} );
        $opts->{parent_uid} = $uinfo->{id};
    }
    else {
        $opts->{parent_uid} = $info->{first_change_id};
    }

    $opts->{message} ||= $self->prompt_edit( opts => $self );

    my @add;
    foreach my $id ( @{ $opts->{add} || [] } ) {
        my $exists = $dbw->xarrayref(
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
    foreach my $id ( @{ $opts->{remove} || [] } ) {
        my $exists = $dbw->xarrayref(
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

    $dbw->txn(
        sub {
            my $uid = $self->new_change(
                message   => $opts->{message},
                parent_id => $opts->{parent_uid},
            );

            foreach my $host_id (@add) {
                $dbw->xdo(
                    insert_into => 'func_update_plan',
                    values      => {
                        change_id  => $uid,
                        id         => $info->{id},
                        add_remove => 1,
                        host_id    => $host_id,
                    },
                );
            }

            foreach my $host_id (@remove) {
                $dbw->xdo(
                    insert_into => 'func_update_plan',
                    values      => {
                        change_id  => $uid,
                        id         => $info->{id},
                        add_remove => 0,
                        host_id    => $host_id,
                    },
                );
            }

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "update plan %s",
                    action_topic_id_1 => $info->{id},
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            print "Plan changed: $opts->{id}.$uid\n";
        }
    );

    return $self->ok('ChangePlan');
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-update-plan - update or comment an plan

=head1 VERSION

0.1.2 (2014-10-08)

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

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

