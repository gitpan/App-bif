package App::bif::log::repo;
use strict;
use warnings;
use utf8;
use feature 'state';
use parent 'App::bif::Context';
use Text::FormatTable;
use Time::Duration qw/ago/;

our $VERSION = '0.1.0_27';

sub run_by_time {
    my $self = shift;
    my $now  = time;
    my $db   = $self->db;
    my ( $dark, $reset, $bold ) = $self->colours(qw/dark reset bold/);

    state $have_thinsql = DBIx::ThinSQL->import(qw/concat qv case/);

    my $latest = $db->xval(
        select => 'bif.update_id',
        from   => 'bifkv bif',
        where  => { 'bif.key' => 'last_sync' },
    );

    my $sth = $db->xprepare(
        select => [
            concat(
                case (
                    when => [ 'NOT u.local AND u.id > ', qv($latest) ],
                    then => qv($bold),
                    else => qv(''),
                ),
                q{strftime('%H:%M:%S',u.mtime,'unixepoch','localtime')},
                qv('  '),
                'u.action',
            ),
            '"u" || u.id',
            q{strftime('%Y-%m-%d',u.mtime,'unixepoch','localtime') AS mdate},
            'u.local',
            qq{$now - strftime('%s', u.mtime, 'unixepoch')},
            'COALESCE(u.author,e.name) AS author',
        ],
        from       => 'updates u',
        inner_join => 'entities e',
        on         => 'e.id = u.identity_id',
        order_by   => [ 'u.mtime DESC', 'u.id DESC' ],
    );

    $sth->execute;

    $self->start_pager;

    my @days = (
        qw/Sunday Monday Tuesday Wednesday Thursday Friday
          Saturday/
    );

    my $mdate = '';
    my $table = Text::FormatTable->new(' l  l  r ');

    while ( my $n = $sth->arrayref ) {
        if ( $n->[2] ne $mdate ) {
            if ( $mdate ne '' ) {
                print $table->render . "\n";
                $table = Text::FormatTable->new(' l  l  r ');

            }
            $mdate = $n->[2];
            $table->head( $dark . $n->[2] . ' (' . ago( $n->[4], 1 ) . ')',
                , 'Author', 'UID' . $reset );

            if ($dark) {
                $table->rule( $dark . '–' . $reset );
            }
            else {
                $table->rule('-');
            }
        }

        if ( $n->[5] ) {

        }
        $table->row( $n->[0], $n->[5], $n->[1] . $reset );
    }

    print $table->render;

    $self->end_pager;
    return $self->ok('LogRepoTime');
}

sub run_by_uid {
    my $self = shift;
    return $self->err('NotImplemented');
}

sub run {
    my $self = __PACKAGE__->new(shift);

    if ( $self->{order} eq 'time' ) {
        return run_by_time($self);
    }
    elsif ( $self->{order} eq 'uid' ) {
        return run_by_uid($self);
    }

    return $self->err( 'InvalidOrder', 'invalid order (time|uid): %s',
        $self->{order} );
}

1;
__END__

=head1 NAME

bif-log-repo - review the history of the current repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log repo [OPTIONS...]

=head1 DESCRIPTION

The C<bif log repo> command displays the history of all actions in the
repository.

=head1 ARGUMENTS & OPTIONS

=over

=item --order uid | time

Order the events by time they occured (time) or in the order in which
they were added to the repository (uid).

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

