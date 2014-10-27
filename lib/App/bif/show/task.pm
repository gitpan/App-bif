package App::bif::show::task;
use strict;
use warnings;
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif::show';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;
    my $info = $self->get_topic( $self->uuid2id( $opts->{id} ), 'task' );
    my $now  = $self->now;

    DBIx::ThinSQL->import(qw/sum qv concat coalesce/);

    my $ref = $db->xhashref(
        select => [
            't.id AS id',
            'substr(t.uuid,1,8) as uuid',
            'p.fullpath AS path',
            'h.name AS hub',
            'hr.location',
            'substr(t2.uuid,1,8) AS project_uuid',
            'tasks.title AS title',
            't.ctime AS ctime',
            't.ctimetz AS ctimetz',
            't.ctimetzhm AS ctimetzhm',
            "$now - t.ctime AS ctime_age",
            'c2.mtime AS mtime',
            'c2.mtimetz AS mtimetz',
            'c2.mtimetzhm AS mtimetzhm',
            "$now - c2.mtime AS mtime_age",
            'c1.author AS author',
            'c1.email AS email',
            'c1.message AS message',
            'ts.status AS status',
            'c12.mtime AS smtime',
            'e1.name as creator',
            'e2.name as updator',
        ],
        from       => 'topics t',
        inner_join => 'changes c1',
        on         => 'c1.id = t.first_change_id',
        inner_join => 'entities e1',
        on         => 'e2.id = c2.identity_id',
        inner_join => 'changes c2',
        on         => 'c2.id = t.last_change_id',
        inner_join => 'entities e2',
        on         => 'e1.id = c1.identity_id',
        inner_join => 'tasks',
        on         => 'tasks.id = t.id',
        inner_join => 'task_status ts',
        on         => 'ts.id = tasks.task_status_id',
        inner_join => 'projects p',
        on         => 'p.id = ts.project_id',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        left_join  => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        inner_join => 'topics t2',
        on         => 't2.id = p.id',
        inner_join => 'changes AS c12',
        on         => 'c12.id = tasks.change_id',
        where      => [ 't.id = ', qv( $info->{id} ) ],
    );

    my @data;
    my ($bold) = $self->colours('bold');

    push( @data, $self->header( '  UUID', $ref->{uuid} ) );
    my ( $t1, $t2 ) = $self->ctime_ago($ref);
    push( @data,
        $self->header( '  Created-By', "$ref->{creator} ($t1)", $t2 ),
    );

    push( @data, $self->header( '  Status', "$ref->{status} [$ref->{path}]" ) );

    if ( $opts->{full} ) {
        require Text::Autoformat;
        push(
            @data,
            $self->header(
                'Description',
                Text::Autoformat::autoformat(
                    $ref->{message},
                    {
                        right => 60,
                        all   => 1
                    }
                )
            ),
        );
    }

    ( $t1, $t2 ) = $self->mtime_ago($ref);
    push( @data,
        $self->header( '  Updated-By', "$ref->{updator} ($t1)", $t2 ),
    ) unless $ref->{mtime} == $ref->{ctime};

    $self->start_pager;
    print $self->render_table( 'l  l', [ $bold . 'Task', $ref->{title} ],
        \@data, 1 );

    $self->ok( 'ShowTask', \@data );

}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show-task - display a task's current status

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif show task ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-task> command displays the characteristics of an task.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

A task ID. Required.

=item --full, -f

Display a more verbose version of the current status.

=item --uuid, -U

Lookup the topic using ID as a UUID string instead of a topic integer.

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

