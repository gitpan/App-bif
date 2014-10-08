package App::bif::log::project;
use strict;
use warnings;
use feature 'state';
use Bif::Mo;

our $VERSION = '0.1.2';
extends 'App::bif::log';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;
    my $info = $self->get_project( $opts->{path} );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat /);

    my $sth = $db->xprepare(
        select => [
            'project_deltas.project_id AS id',
            'SUBSTR(t.uuid,1,8) AS uuid',
            concat( qv('c'), 'changes.id' )->as('change_id'),
            'SUBSTR(changes.uuid,1,8) AS change_uuid',
            'project_deltas.title',
            'changes.mtime',
            'changes.mtimetz',
            'changes.action',
            'COALESCE(changes.author,e.name) AS author',
            'COALESCE(changes.email,ecm.mvalue) AS email',
            'changes.message',
            'changes_tree.depth',
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
        inner_join => 'changes_tree',
        on         => 'changes_tree.parent = t.first_change_id AND
                       changes_tree.child = project_deltas.change_id',
        inner_join => 'changes',
        on         => 'changes.id = changes_tree.child',
        inner_join => 'entities e',
        on         => 'e.id = changes.identity_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        left_join  => 'project_status',
        on         => 'project_status.id = project_deltas.status_id',
        where      => {
            'project_deltas.project_id' => $info->{id},
        },
        order_by => 'changes.path asc',
    );

    $sth->execute;

    $self->start_pager;

    my $first = $sth->hashref;
    $self->log_item( $first, 'project', [ 'Phase', $first->{status} ] );
    $self->log_comment($_) for $sth->hashrefs;

    return $self->ok('LogProject');
}

1;
__END__

=head1 NAME

=for bif-doc #history

bif-log-project - review a project history

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif log project PATH [OPTIONS...]

=head1 DESCRIPTION

The B<bif-log-project> command displays a project history.

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

