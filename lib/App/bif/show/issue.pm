package App::bif::show::issue;
use strict;
use warnings;
use Bif::Mo;
use DBIx::ThinSQL qw/sum case coalesce concat qv/;

our $VERSION = '0.1.4';
extends 'App::bif::show';

sub run {
    my $self   = shift;
    my $opts   = $self->opts;
    my $db     = $self->db;
    my $info   = $self->get_topic( $self->uuid2id( $opts->{id} ), 'issue' );
    my ($bold) = $self->colours('bold');
    my $now    = $self->now;
    my @data;

    my $ref = $db->xhashref(
        select => [
            'SUBSTR(t.uuid,1,8) as uuid',
            'i.title',
            't.ctime',
            't.ctimetz',
            't.ctimetzhm AS ctimetzhm',
            "$now - t.ctime AS ctime_age",
            't.mtime',
            't.mtimetz',
            't.mtimetzhm AS mtimetzhm',
            "$now - t.mtime AS mtime_age",
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
        inner_join => 'issues i',
        on         => 'i.id = t.id',
        where      => { 't.id' => $info->{id} },
    );

    push( @data, $self->header( '  UUID', $ref->{uuid} ), );
    my ( $t1, $t2 ) = $self->ctime_ago($ref);
    push( @data,
        $self->header( '  Created-By', "$ref->{creator} ($t1)", $t2 ),
    );

    my @refs = $db->xhashrefs(
        select => [
            'pi.id AS id',
            'p.fullpath AS path',
            'ist.status',
            'c.mtime AS mtime',
            'c.mtimetz AS mtimetz',
            'c.mtimetzhm AS mtimetzhm',
            "$now - c.mtime AS mtime_age",
            'p.hub_id',
        ],
        from       => 'project_issues pi',
        inner_join => 'projects p',
        on         => 'p.id = pi.project_id',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        inner_join => 'issue_status ist',
        on         => 'ist.id = pi.issue_status_id',
        inner_join => 'changes c',
        on         => 'c.id = pi.change_id',
        where      => { 'pi.issue_id' => $info->{id} },
        order_by   => [ 'p.hub_id IS NOT NULL', 'path' ],
    );

    my %seen;
    my $count = @refs;
    my $i     = 1;
    foreach my $ref (@refs) {
        my @ago = $self->mtime_ago($ref);

        push(
            @data,
            $self->header(
                '  Status', "$ref->{status} [$ref->{path}] (" . $ago[0] . ')',
                $ago[1]
            ),
        );
    }

    ( $t1, $t2 ) = $self->mtime_ago($ref);
    push( @data,
        $self->header( '  Updated-By', "$ref->{updator} ($t1)", $t2 ),
    ) unless $ref->{mtime} == $ref->{ctime};

    $self->start_pager;
    print $self->render_table( 'l  l', [ $bold . 'Issue', $ref->{title} ],
        \@data, 1 );

    $self->ok( 'ShowIssue', \@data );
}

1;
__END__

=head1 NAME

=for bif-doc #show

bif-show-issue - display an issue's current status

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif show issue ID [OPTIONS...]

=head1 DESCRIPTION

The B<bif-show-issue> command displays the characteristics of an issue.

=head1 ARGUMENTS & OPTIONS

=over

=item ID

An issue ID. Required.

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

