package App::bif::log::issue;
use strict;
use warnings;
use feature 'state';
use Bif::Mo;

our $VERSION = '0.1.4';
extends 'App::bif::log';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;
    my $info = $self->get_topic( $opts->{id}, 'issue' );

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv concat /);
    my $now = $self->now;

    my $sth = $db->xprepare(
        select => [
            'project_issues.issue_id AS "id"',
            concat( qv('c'), 'changes.id' )->as('change_id'),
            'SUBSTR(changes.uuid,1,8) AS change_uuid',
            'changes.mtime AS mtime',
            "changes.mtimetz AS mtimetz",
            'changes.mtimetzhm AS mtimetzhm',
            "$now - changes.mtime AS mtime_age",
            concat( 'changes.action', qv(' '), 'project_issues.id' )
              ->as('action'),
            'COALESCE(changes.author,e.name) AS author',
            'COALESCE(changes.email,ecm.mvalue) AS email',
            'changes.message',
            'changes.ucount',
            'issue_status.status',
            'issue_deltas.title',
            'projects.path',
            'changes_tree.depth',
        ],
        from       => 'issue_deltas',
        inner_join => 'changes',
        on         => 'changes.id = issue_deltas.change_id',
        inner_join => 'entities e',
        on         => 'e.id = changes.identity_id',
        inner_join => 'entity_contact_methods ecm',
        on         => 'ecm.id = e.default_contact_method_id',
        inner_join => 'projects',
        on         => 'projects.id = issue_deltas.project_id',
        inner_join => 'project_issues',
        on         => {
            'project_issues.project_id' => \'issue_deltas.project_id',
            'project_issues.issue_id'   => \'issue_deltas.issue_id',
        },
        left_join  => 'issue_status',
        on         => 'issue_status.id = issue_deltas.issue_status_id',
        inner_join => 'changes_tree',
        on         => {
            'changes_tree.child'  => \'changes.id',
            'changes_tree.parent' => $info->{first_change_id}
        },
        where    => { 'issue_deltas.issue_id' => $info->{id} },
        order_by => 'changes.path ASC',
    );

    $sth->execute;
    $self->start_pager;

    my $first = $sth->hashref;
    $first->{ctime}     = $first->{mtime};
    $first->{ctimetz}   = $first->{mtimetz};
    $first->{ctimetzhm} = $first->{mtimetzhm};
    $first->{ctime_age} = $first->{mtime_age};
    $self->log_item( $first, 'issue' );

    $self->log_comment($_) for $sth->hashrefs;

    return $self->ok('LogIssue');
}

1;
__END__

=head1 NAME

=for bif-doc #history

bif-log-issue - review the history of a issue

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif log issue ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-log-issue> command displays the history of an issue.

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

