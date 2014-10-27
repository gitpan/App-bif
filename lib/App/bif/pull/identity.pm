package App::bif::pull::identity;
use strict;
use warnings;
use AnyEvent;
use Bif::Sync::Client;
use Bif::Mo;
use Coro;
use DBIx::ThinSQL qw/qv/;
use Log::Any '$log';

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $cv   = AE::cv;
    my $dbw  = $self->dbw;

    $opts->{message} ||= "Importing identity from $opts->{location}";

    $|++;

    my $error;
    my $client = Bif::Sync::Client->new(
        name          => $opts->{location},
        db            => $dbw,
        location      => $opts->{location},
        debug         => $opts->{debug},
        debug_bifsync => $opts->{debug_bifsync},
        on_update     => sub {
            $self->lprint("Importing identity ($opts->{location}): $_[0]");
        },
        on_error => sub {
            $error = shift;
            $cv->send;
        },
    );

    my $coro = async {
        select $App::bif::pager->fh if $opts->{debug};

        eval {
            $dbw->txn(
                sub {
                    my $uid = $dbw->nextval('changes');

                    if ( !$opts->{self} ) {
                        $self->new_change(
                            id      => $uid,
                            message => $opts->{message},
                        );
                    }

                    $|++;
                    my $status = $client->bootstrap_identity;

                    unless ( $status eq 'IdentityImported' ) {
                        $dbw->rollback;
                        $error = "unexpected status received: $status";
                        return;
                    }

                    if ( $opts->{self} ) {
                        $self->new_change(
                            id      => $uid,
                            message => $opts->{message},
                        );
                    }

                    my $iid = $dbw->xval(
                        select => 'bifkv.identity_id',
                        from   => 'bifkv',
                        where  => { key => 'bootstrap' },
                    );

                    $dbw->xdo(
                        insert_into => 'change_deltas',
                        values      => {
                            new       => 1,      # TODO why am I doing this?
                            change_id => $uid,
                            action_format     => 'pull identity %s',
                            action_topic_id_1 => $iid,
                        },
                    );

                    $dbw->xdo(
                        insert_into => 'func_merge_changes',
                        values      => { merge => 1 },
                    );

                    $dbw->xdo(
                        insert_or_replace_into =>
                          [ 'bifkv', qw/key change_id change_id2/ ],
                        select => [ qv('last_sync'), $uid, 'MAX(c.id)', ],
                        from   => 'changes c',
                    );

                    print "\n";
                }
            );
        };

        if ($@) {
            $error = $@;
        }

        $client->disconnect;
        return $cv->send( !$error );
    };

    return $self->err( 'Unknown', $error ) unless $cv->recv;
    return $self->ok('PullIdentity');
}

1;
__END__

=head1 NAME

=for bif-doc #sync

bif-pull-identity - import an identity from a repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif pull identity LOCATION [OPTIONS...]

=head1 DESCRIPTION

The B<bif-pull-identity> command imports an identity from a repository.

=head1 ARGUMENTS & OPTIONS

=over

=item LOCATION

The location of the identity repository.

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

