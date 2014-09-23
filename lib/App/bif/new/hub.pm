package App::bif::new::hub;
use strict;
use warnings;
use parent 'App::bif::Context';
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;

    $self->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $self->{message} ||= "New hub $self->{name}";

    $db->txn(
        sub {
            my $uid = $self->new_change( message => $self->{message}, );
            my $id = $db->nextval('topics');

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    kind      => 'hub',
                },
            );

            $db->xdo(
                insert_into => 'func_new_hub',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    name      => $self->{name},
                },
            );

            foreach my $loc ( @{ $self->{locations} } ) {
                my $rid = $db->nextval('topics');
                $db->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        id        => $rid,
                        change_id => $uid,
                        kind      => 'hub_repo',
                    },
                );

                $db->xdo(
                    insert_into => 'func_new_hub_repo',
                    values      => {
                        id        => $rid,
                        change_id => $uid,
                        hub_id    => $id,
                        location  => $loc,
                    },
                );
            }

            $db->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new hub (%s) $self->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            if ( $self->{default} ) {
                $db->xdo(
                    update => 'hubs',
                    set    => { local => 1 },
                    where  => { id => $id },
                );
            }

            printf( "Hub created: %s\n", $self->{name} );

            # For test scripts
            $self->{id}        = $id;
            $self->{change_id} = $uid;
        }
    );

    return $self->ok('NewHub');
}

1;
__END__

=head1 NAME

bifhub-new-hub - create a new hub in the repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif new hub [NAME] [LOCATIONS...] [OPTIONS...]

=head1 DESCRIPTION

The C<bifhub new hub> command creates a new hub representing an a
project organisation.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the hub.

=item LOCATIONS

The locations of the hub repositories.

=item --default

Mark this hub as local/default.

=item --message, -m MESSAGE

The creation message, set to "" by default.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

