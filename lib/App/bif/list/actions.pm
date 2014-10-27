package App::bif::list::actions;
use strict;
use warnings;
use utf8;
use feature 'state';
use Bif::Mo;
use Text::FormatTable;
use Time::Duration qw/ago/;

our $VERSION = '0.1.4';
extends 'App::bif::log';

sub run_by_time {
    my $self = shift;
    my $opts = $self->opts;
    my $now  = $self->now;
    my $db   = $self->db;
    my ( $dark, $reset, $yellow ) = $self->colours(qw/yellow reset yellow/);

    state $have_thinsql = DBIx::ThinSQL->import(qw/concat coalesce qv case sq/);

    my $sth = $db->xprepare(
        with => 'b',
        as   => sq(
            select => [ 'b.change_id AS start', 'b.change_id2 AS stop' ],
            from   => 'bifkv b',
            where => { 'b.key' => 'last_sync' },
        ),
        select => [
            q{strftime('%H:%M:%S',c.mtime,'unixepoch','localtime')},
            '"c" || c.id',
            'COALESCE(c.author,i.shortname,e.name) AS author',
            "COALESCE(p.fullpath,'')  AS project",
            concat(
                'c.action',
                case (
                    when => 'b.start',
                    then => qv( $yellow . ' [+]' . $reset ),
                    else => qv(''),
                )
            ),
            q{strftime('%Y-%m-%d',c.mtime,'unixepoch','localtime') AS mdate},
            qq{$now - strftime('%s', c.mtime, 'unixepoch')},
        ],
        from       => 'changes c',
        left_join  => 'change_deltas cd',
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
        on         => 'ts.id = t.task_status_id',
        left_join  => 'projects p',
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
    my $table = Text::FormatTable->new(' l  l  l  l ');

    while ( my $n = $sth->arrayref ) {
        if ( $n->[5] ne $mdate ) {
            $table->rule(' ') if $mdate;
            $mdate = $n->[5];
            $table->head(
                $dark . $n->[5],
                'Who', 'Project',
                'Action [from ' . ago( $n->[6], 1 ) . ']' . $reset,
            );

        }

        $table->row( $n->[0], $n->[2], $n->[3], $n->[4] );
    }

    print $table->render . "\n";

    return $self->ok('ListActionsTime');
}

sub run_by_uid {
    my $self = shift;
    my $opts = $self->opts;
    my $now  = $self->now;
    my $db   = $self->db;
    my ( $dark, $reset, $yellow ) = $self->colours(qw/yellow reset yellow/);

    state $have_thinsql = DBIx::ThinSQL->import(qw/concat coalesce qv case sq/);

    my $sth = $db->xprepare(
        with => 'b',
        as   => sq(
            select => [ 'b.change_id AS start', 'b.change_id2 AS stop' ],
            from   => 'bifkv b',
            where => { 'b.key' => 'last_sync' },
        ),
        select => [
            '"c" || c.id',
            q{strftime('%Y-%m-%d-%H:%M:%S',c.mtime,'unixepoch','localtime')},
            'COALESCE(c.author,i.shortname,e.name) AS author',
            "COALESCE(p.fullpath,'')  AS project",
            concat(
                'c.action',
                case (
                    when => 'b.start',
                    then => qv( $yellow . ' [+]' . $reset ),
                    else => qv(''),
                )
            ),
        ],
        from       => 'changes c',
        left_join  => 'change_deltas cd',
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
        on         => 'ts.id = t.task_status_id',
        left_join  => 'projects p',
        on         => 'p.id = ts.project_id OR p.id = cd.action_topic_id_1',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        order_by   => ['c.id DESC'],
    );

    $sth->execute;

    my $data = $sth->arrayrefs || return $self->ok('ListActionsUid');
    $self->start_pager( scalar @$data );

    print $self->render_table( ' l  l  l  l  l ',
        [ 'CID', 'Date', 'Who', 'Project', 'Action' ], $data );

    return $self->ok('ListActionsUid');
}

sub run {
    my $self = shift;
    my $opts = $self->opts;

    return run_by_uid($self) if $opts->{action};
    return run_by_time($self);
}

1;
__END__

=head1 NAME

=for bif-doc #history

bif-list-actions - review the actions in the current repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif list actions [OPTIONS...]

=head1 DESCRIPTION

The B<bif-list-actions> command lists the actions that have occured in
the repository. By default they are ordered by time and are grouped by
day.

=head1 ARGUMENTS & OPTIONS

=over

=item --action, -a

Sort actions in the order in which they were added to the repository.

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

