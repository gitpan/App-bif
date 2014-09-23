package App::bif::log::repo;
use strict;
use warnings;
use utf8;
use feature 'state';
use parent 'App::bif::Context';
use Text::FormatTable;
use Time::Duration qw/ago/;

our $VERSION = '0.1.0_28';

sub run_by_time {
    my $self = shift;
    my $now  = time;
    my $db   = $self->db;
    my ( $dark, $reset, $bold ) = $self->colours(qw/dark reset bold/);

    state $have_thinsql = DBIx::ThinSQL->import(qw/concat qv case sq/);

    my $join = $self->{full} ? 'left_join' : 'inner_join';

    my $sth = $db->xprepare(
        with => 'b',
        as   => sq(
            select => [ 'b.change_id AS start', 'b.change_id2 AS stop' ],
            from   => 'bifkv b',
            where => { 'b.key' => 'last_sync' },
        ),
        select => [
            concat(
                case (
                    when => 'b.start',
                    then => qv($bold),
                    else => qv(''),
                ),
                q{strftime('%H:%M:%S',c.mtime,'unixepoch','localtime')},
                qv('  '),
                'c.action',
            ),
            '"c" || c.id',
            q{strftime('%Y-%m-%d',c.mtime,'unixepoch','localtime') AS mdate},
            qq{$now - strftime('%s', c.mtime, 'unixepoch')},
            'COALESCE(c.author,i.shortname,e.name) AS author',
            "COALESCE(p.path || COALESCE('\@' || h.name,''),'') AS project",
        ],
        from       => 'changes c',
        inner_join => 'change_deltas cd',
        on         => 'cd.change_id = c.id',
        inner_join => 'entities e',
        on         => 'e.id = c.identity_id',
        inner_join => 'identities i',
        on         => 'i.id = c.identity_id',
        left_join  => 'b',
        on         => 'c.id BETWEEN b.start+1 AND b.stop',
        left_join  => 'tasks t',
        on         => 't.id = cd.action_topic_id_1',
        left_join  => 'task_status ts',
        on         => 'ts.id = t.status_id',
        $join      => 'projects p',
        on         => 'p.id = ts.project_id OR p.id = cd.action_topic_id_1',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        order_by   => [ 'c.mtime DESC', 'c.id DESC' ],
    );

    $sth->execute;

    $self->start_pager;

    my @days = (
        qw/Sunday Monday Tuesday Wednesday Thursday Friday
          Saturday/
    );

    my $mdate = '';
    my $table = Text::FormatTable->new(' l  l  l  r ');

    while ( my $n = $sth->arrayref ) {
        if ( $n->[2] ne $mdate ) {
            $table->rule(' ') if $mdate;
            $mdate = $n->[2];
            $table->head(
                $dark . $n->[2] . ' (' . uc( ago( $n->[3], 1 ) ) . ')',
                , 'PROJECT', 'AUTHOR', 'CID' . $reset );

        }

        if ( $n->[4] ) {

        }
        $table->row( $n->[0], $n->[5], $n->[4], $n->[1] . $reset );
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

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif log repo [OPTIONS...]

=head1 DESCRIPTION

The C<bif log repo> command displays the history of all actions in the
repository.

=head1 ARGUMENTS & OPTIONS

=over

=item --full, -f

Include all actions (not just project-related) in the output.

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

