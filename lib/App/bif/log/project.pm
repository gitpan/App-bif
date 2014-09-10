package App::bif::log::project;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::log';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_project( $self->{path} );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat /);

    my $sth = $db->xprepare(
        select => [
            'project_deltas.project_id AS id',
            'SUBSTR(t.uuid,1,8) AS uuid',
            concat( qv('u'), 'updates.id' )->as('update_id'),
            'SUBSTR(updates.uuid,1,8) AS update_uuid',
            'project_deltas.title',
            'updates.mtime',
            'updates.mtimetz',
            'updates.action',
            'updates.author',
            'updates.email',
            'updates.message',
            'updates_tree.depth',
            'project_status.status',
            'project_status.status',
            'projects.path',
            'project_deltas.name',
        ],
        from       => 'project_deltas',
        inner_join => 'projects',
        on         => 'projects.id = project_deltas.project_id',
        inner_join => 'topics t',
        on         => 't.id = projects.id',
        inner_join => 'updates_tree',
        on         => 'updates_tree.parent = t.first_update_id AND
                       updates_tree.child = project_deltas.update_id',
        inner_join => 'updates',
        on         => 'updates.id = updates_tree.child',
        left_join  => 'project_status',
        on         => 'project_status.id = project_deltas.status_id',
        where      => {
            'project_deltas.project_id' => $info->{id},
        },
        order_by => 'updates.path asc',
    );

    $sth->execute;

    $self->start_pager;

    $self->init;
    my $first = $sth->hashref;
    $self->log_item( $first, 'project', [ 'Phase', $first->{status} ] );
    $self->log_comment($_) for $sth->hashrefs;

    $self->end_pager;
    return $self->ok('LogProject');
}

1;
__END__

=head1 NAME

bif-log-project - review a project history

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log project PATH [OPTIONS...]

=head1 DESCRIPTION

The C<bif log project> command displays a project history.

=head1 ARGUMENTS & OPTIONS

=over

=item PATH

A project PATH or ID. Required.

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

