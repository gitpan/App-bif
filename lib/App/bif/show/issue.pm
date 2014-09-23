package App::bif::show::issue;
use strict;
use warnings;
use parent 'App::bif::show';
use DBIx::ThinSQL qw/qv case concat/;

our $VERSION = '0.1.0_28';

sub run {
    my $self   = __PACKAGE__->new(shift);
    my $db     = $self->db;
    my $info   = $self->get_topic( $self->uuid2id( $self->{id} ), 'issue' );
    my ($bold) = $self->colours('bold');
    my @data;

    $self->init;

    my $ref = $db->xhashref(
        select => [
            'SUBSTR(t.uuid,1,8) as uuid', 'i.title',
            't.ctime',                    't.ctimetz',
            't.mtime',                    't.mtimetz',
        ],
        from       => 'topics t',
        inner_join => 'issues i',
        on         => 'i.id = t.id',
        where      => { 't.id' => $info->{id} },
    );

    push( @data, $self->header( '  UUID', $ref->{uuid} ), );
    push(
        @data,
        $self->header(
            '  Created', $self->ago( $ref->{ctime}, $ref->{ctimetz} )
        ),
    );

    my @refs = $db->xhashrefs(
        select => [
            'pi.id AS id',
            concat(
                'p.path',
                case (
                    when => 'h.id IS NOT NULL',
                    then => concat( qv('@'), 'h.name' ),
                    else => qv(''),
                )
              )->as('path'),
            'ist.status',
            'c.mtime AS mtime',
            'c.mtimetz AS mtimetz',
        ],
        from       => 'project_issues pi',
        inner_join => 'projects p',
        on         => 'p.id = pi.project_id',
        left_join  => 'hubs h',
        on         => 'h.id = p.hub_id',
        inner_join => 'issue_status ist',
        on         => 'ist.id = pi.status_id',
        inner_join => 'changes c',
        on         => 'c.id = pi.change_id',
        where      => { 'pi.issue_id' => $info->{id} },
        order_by   => 'path',
    );

    my %seen;
    my $count = @refs;
    my $i     = 1;
    foreach my $ref (@refs) {
        my @ago = $self->ago( $ref->{mtime}, $ref->{mtimetz} );

        push(
            @data,
            $self->header(
                '  Status', "$ref->{status} [$ref->{path}] (" . $ago[0] . ')',
                $ago[1]
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
    print $self->render_table( 'l  l', $self->header( 'Issue', $ref->{title} ),
        \@data, 1 );
    $self->end_pager;

    $self->ok( 'ShowIssue', \@data );
}

1;
__END__

=head1 NAME

bif-show-issue - display an issue's current status

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif show issue ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show issue> command displays the characteristics of an issue.

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

