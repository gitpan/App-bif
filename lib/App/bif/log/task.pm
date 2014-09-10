package App::bif::log::task;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::log';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_topic( $self->{id}, 'task' );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat /);

    my $sth = $db->xprepare(
        select => [
            'task_deltas.task_id AS id',
            'SUBSTR(t.uuid,1,8) AS uuid',
            concat( qv('u'), 'task_deltas.update_id' )->as('update_id'),
            'SUBSTR(updates.uuid,1,8) AS update_uuid',
            'task_deltas.title',
            'updates.mtime',
            'updates.mtimetz',
            'updates.action',
            'updates.author',
            'updates.email',
            'task_status.status',
            'task_status.status',
            'projects.path',
            'projects.title AS project_title',
            'updates_tree.depth',
            'updates.message',
        ],
        from       => 'task_deltas',
        inner_join => 'updates',
        on         => 'updates.id = task_deltas.update_id',
        inner_join => 'topics t',
        on         => 't.id = task_deltas.task_id',
        left_join  => 'task_status',
        on         => 'task_status.id = task_deltas.status_id',
        left_join  => 'projects',
        on         => 'projects.id = task_status.project_id',
        inner_join => 'updates_tree',
        on         => {
            'updates_tree.parent' => $info->{first_update_id},
            'updates_tree.child'  => \'task_deltas.update_id'
        },
        where    => { 'task_deltas.task_id' => $info->{id} },
        order_by => 'updates.path ASC',
    );

    $sth->execute;

    $self->start_pager;

    $self->init;
    $self->log_item( $sth->hashref, 'task' );
    $self->log_comment($_) for $sth->hashrefs;

    $self->end_pager;
    return $self->ok('LogTask');
}

1;
__END__

=head1 NAME

bif-log-task - review a task history

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log task ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif log task> command displays a task history.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

A task ID.

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

