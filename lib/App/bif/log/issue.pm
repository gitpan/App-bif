package App::bif::log::issue;
use strict;
use warnings;
use feature 'state';
use parent 'App::bif::log';

our $VERSION = '0.1.0_27';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->db;
    my $info = $self->get_topic( $self->{id}, 'issue' );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat /);

    my $sth = $db->xprepare(
        select => [
            'project_issues.issue_id AS "id"',
            concat( qv('u'), 'updates.id' )->as('update_id'),
            'SUBSTR(updates.uuid,1,8) AS update_uuid',
            'updates.mtime',
            'updates.mtimetz',
            concat( 'updates.action', qv(' '), 'project_issues.id' )
              ->as('action'),
            'updates.author',
            'updates.email',
            'updates.message',
            'updates.ucount',
            'issue_status.status',
            'issue_deltas.title',
            'projects.path',
            'updates_tree.depth',
        ],
        from       => 'issue_deltas',
        inner_join => 'updates',
        on         => 'updates.id = issue_deltas.update_id',
        inner_join => 'projects',
        on         => 'projects.id = issue_deltas.project_id',
        inner_join => 'project_issues',
        on         => {
            'project_issues.project_id' => \'issue_deltas.project_id',
            'project_issues.issue_id'   => \'issue_deltas.issue_id',
        },
        left_join  => 'issue_status',
        on         => 'issue_status.id = issue_deltas.status_id',
        inner_join => 'updates_tree',
        on         => {
            'updates_tree.child'  => \'updates.id',
            'updates_tree.parent' => $info->{first_update_id}
        },
        where    => { 'issue_deltas.issue_id' => $info->{id} },
        order_by => 'updates.path ASC',
    );

    $sth->execute;
    $self->start_pager;

    $self->init;
    $self->log_item( $sth->hashref, 'issue' );
    $self->log_comment($_) for $sth->hashrefs;

    $self->end_pager;
    return $self->ok('LogIssue');
}

1;
__END__

=head1 NAME

bif-log-issue - review the history of a issue

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif log issue ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif log issue> command displays the history of an issue.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

The ID of a issue. Required.

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

