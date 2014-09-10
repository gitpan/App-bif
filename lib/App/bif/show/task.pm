package App::bif::show::task;
use strict;
use warnings;
use parent 'App::bif::show';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_topic( $self->uuid2id( $self->{id} ), 'task' );

    DBIx::ThinSQL->import(qw/sum qv concat/);

    my $ref = $db->xhashref(
        select => [
            'topics.id AS id',
            'substr(topics.uuid,1,8) as uuid',
            'projects.path',
            'h.name AS hub',
            'hr.location',
            'substr(topics2.uuid,1,8) AS project_uuid',
            'tasks.title AS title',
            'topics.mtime AS mtime',
            'topics.mtimetz AS mtimetz',
            'topics.ctime AS ctime',
            'topics.ctimetz AS ctimetz',
            'updates.author AS author',
            'updates.email AS email',
            'updates.message AS message',
            'task_status.status AS status',
            'updates2.mtime AS smtime',
        ],
        from       => 'topics',
        inner_join => 'updates',
        on         => 'updates.id = topics.first_update_id',
        inner_join => 'tasks',
        on         => 'tasks.id = topics.id',
        inner_join => 'task_status',
        on         => 'task_status.id = tasks.status_id',
        inner_join => 'projects',
        on         => 'projects.id = task_status.project_id',
        left_join  => 'hubs h',
        on         => 'h.id = projects.hub_id',
        left_join  => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        inner_join => 'topics AS topics2',
        on         => 'topics2.id = projects.id',
        inner_join => 'updates AS updates2',
        on         => 'updates2.id = tasks.update_id',
        where      => [ 'topics.id = ', qv( $info->{id} ) ],
    );

    $self->init;

    my @data;
    my ($bold) = $self->colours('bold');
    my @ago = $self->ago( $ref->{smtime}, $ref->{mtimetz} );

    push( @data, $self->header( '  ID', "$ref->{id}", $ref->{uuid} ), );

    if ( $ref->{hub} ) {
        push(
            @data,
            $self->header(
                '  Project',
                "$ref->{path}\@$ref->{hub}",
                "$ref->{project_uuid}\@$ref->{location}"
            )
        );
    }
    else {
        push( @data,
            $self->header( '  Project', $ref->{path}, $ref->{project_uuid} ) );
    }

    push(
        @data,
        $self->header(
            '  Status', "$ref->{status} (" . $ago[0] . ')', $ago[1]
        )
    );

    if ( $self->{full} ) {
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

    push(
        @data,
        $self->header(
            '  Updated', $self->ago( $ref->{mtime}, $ref->{mtimetz} )
        ),
    );

    $self->start_pager;
    print $self->render_table( 'l  l', $self->header( 'Task', $ref->{title} ),
        \@data );
    $self->end_pager;

    $self->ok( 'ShowTask', \@data );

}

1;
__END__

=head1 NAME

bif-show-task - display a task's current status

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif show task ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show task> command displays the characteristics of an task.

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

