package App::bif::new::hub;
use strict;
use warnings;
use Bif::Mo;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dbw  = $self->dbw;

    $opts->{name} ||= prompt( 'Name:', '' )
      || return $self->err( 'NameRequired', 'name is required' );

    $opts->{message} ||= "New hub $opts->{name}";

    $dbw->txn(
        sub {
            my $uid = $self->new_change( message => $opts->{message}, );
            my $id = $dbw->nextval('topics');

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    kind      => 'hub',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_hub',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    name      => $opts->{name},
                },
            );

            my $i;
            foreach my $loc ( @{ $opts->{locations} } ) {
                my $rid = $dbw->nextval('topics');
                $dbw->xdo(
                    insert_into => 'func_new_topic',
                    values      => {
                        id        => $rid,
                        change_id => $uid,
                        kind      => 'hub_repo',
                    },
                );

                $dbw->xdo(
                    insert_into => 'func_new_hub_repo',
                    values      => {
                        id        => $rid,
                        change_id => $uid,
                        hub_id    => $id,
                        location  => $loc,
                    },
                );

                $dbw->xdo(
                    update => 'hubs',
                    set    => {
                        default_repo_id => $rid,
                    },
                    where => {
                        id => $id,
                    },
                ) unless $i++;
            }

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new hub (%s) $opts->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            if ( $opts->{default} ) {
                $dbw->xdo(
                    update => 'hubs',
                    set    => { local => 1 },
                    where  => { id => $id },
                );
            }

            printf( "Hub created: %s\n", $opts->{name} );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    return $self->ok('NewHub');
}

1;
__END__

=head1 NAME

=for bif-doc #hubadmin

bif-new-hub - create a new hub in the repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif new hub [NAME] [LOCATIONS...] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-hub> command creates a new hub representing an a project
organisation.

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

