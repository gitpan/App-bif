package App::bif::log::task;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::log';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_topic( $self->{id}, 'task' );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat coalesce/);

    my $sth = $db->xprepare(
        select => [
            'task_deltas.task_id AS id',
            'SUBSTR(t.uuid,1,8) AS uuid',
            concat( qv('c'), 'task_deltas.change_id' )->as('change_id'),
            'SUBSTR(changes.uuid,1,8) AS change_uuid',
            'task_deltas.title',
            'changes.mtime',
            'changes.mtimetz',
            'changes.action',
            'COALESCE(changes.author,e.name) AS author',
            'COALESCE(changes.email,ecm.mvalue) AS email',
            'task_status.status',
            'task_status.status',
            concat( 'projects.path',
                coalesce( concat( qv('@'), 'h.name' ), qv('') ) )->as('path'),
            'projects.title AS project_title',
            'changes_tree.depth',
            'changes.message',
        ],
        from       => 'task_deltas',
        inner_join => 'changes',
        on         => 'changes.id = task_deltas.change_id',
        inner_join => 'entities e',
        on         => 'e.id = changes.identity_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        inner_join => 'topics t',
        on         => 't.id = task_deltas.task_id',
        left_join  => 'task_status',
        on         => 'task_status.id = task_deltas.status_id',
        left_join  => 'projects',
        on         => 'projects.id = task_status.project_id',
        left_join  => 'hubs h',
        on         => 'h.id = projects.hub_id',
        inner_join => 'changes_tree',
        on         => {
            'changes_tree.parent' => $info->{first_change_id},
            'changes_tree.child'  => \'task_deltas.change_id'
        },
        where    => { 'task_deltas.task_id' => $info->{id} },
        order_by => 'changes.path ASC',
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

0.1.0_28 (2014-09-23)

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

