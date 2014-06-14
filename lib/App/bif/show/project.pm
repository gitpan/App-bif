package App::bif::show::project;
use strict;
use warnings;
use App::bif::Context;
use App::bif::show;

our $VERSION = '0.1.0_25';

my $yellow = '';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db;

    my $info = $ctx->get_project( $ctx->{id}, $ctx->{hub} )
      || return $ctx->err(
        'ProjectNotFound',
        "project not found: $ctx->{id}"
          . (
            $ctx->{hub}
            ? "($ctx->{hub})"
            : ''
          )
      );

    App::bif::show::_init;

    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhash(
        select => [
            'topics.id',             'substr(topics.uuid,1,8) as uuid',
            'projects.path',         'projects.title',
            'topics.ctime',          'topics.ctimetz',
            'topics.mtime',          'topics.mtimetz',
            'updates.author',        'updates.email',
            'updates.message',       'project_status.status',
            'project_status.status', 'projects.local',
            'h.name AS hub',         't2.uuid AS hub_uuid',
            'hr.location',
        ],
        from       => 'projects',
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        inner_join => 'updates',
        on         => 'updates.id = topics.first_update_id',
        inner_join => 'project_status',
        on         => 'project_status.id = projects.status_id',
        left_join  => 'hubs h',
        on         => 'h.id = projects.hub_id',
        left_join  => 'hub_repos hr',
        on         => 'hr.id = h.default_repo_id',
        left_join  => 'topics t2',
        on         => 't2.id = h.id',
        where      => { 'projects.id' => $info->{id} },
    );

    push(
        @data,
        App::bif::show::_header(
            $yellow . 'Project',
            $yellow . $ref->{title}
        ),

        App::bif::show::_header( '  Path', $ref->{path}, $ref->{uuid} ),
    );

    push( @data,
        App::bif::show::_header( '  Hub', $ref->{hub}, $ref->{location} ),
    ) if $ref->{hub};

    if ( $ctx->{full} ) {
        push(
            @data,
            App::bif::show::_header(
                '  Creator', $ref->{author}, $ref->{email}
            ),
            App::bif::show::_header(
                '  Created',
                App::bif::show::_new_ago( $ref->{ctime}, $ref->{ctimetz} )
            ),
        );
    }

    my @phases = $db->xarrays(
        select => [
            case (
                when => { status => $ref->{status} },
                then => 'UPPER(status)',
                else => 'status',
            )->as('status'),
        ],
        from     => 'project_status',
        where    => { project_id => $info->{id} },
        order_by => 'rank',
    );

    push(
        @data,
        App::bif::show::_header(
            '  Phases', join( ', ', map { $_->[0] } @phases )
        ),
    );

    if ( $ref->{local} ) {
        my ( $ai, $si, $ri, $ii ) = $db->xarray(
            select => [
                coalesce( sum( { status => 'open' } ),    0 )->as('open'),
                coalesce( sum( { status => 'stalled' } ), 0 )->as('stalled'),
                coalesce( sum( { status => 'closed' } ),  0 )->as('closed'),
                coalesce( sum( { status => 'ignored' } ), 0 )->as('ignored'),
            ],
            from       => 'project_issues',
            inner_join => 'issue_status',
            on         => 'issue_status.id = project_issues.status_id',
            where      => { 'project_issues.project_id' => $info->{id} },
        );

        my ( $at, $st, $rt, $it ) = $db->xarray(
            select => [
                coalesce( sum( { status => 'open' } ),    0 )->as('open'),
                coalesce( sum( { status => 'stalled' } ), 0 )->as('stalled'),
                coalesce( sum( { status => 'closed' } ),  0 )->as('closed'),
                coalesce( sum( { status => 'ignored' } ), 0 )->as('ignored'),
            ],
            from       => 'task_status',
            inner_join => 'tasks',
            on         => 'tasks.status_id = task_status.id',
            where      => { 'task_status.project_id' => $info->{id} },
        );

        my $total_issues = $ai + $si + $ri;
        my $total_tasks  = $at + $st + $rt;
        my $total        = $total_issues + $total_tasks;
        my $progress     = $total ? int( ( ( $ri + $rt ) / $total ) * 100 ) : 0;

        push(
            @data,
            App::bif::show::_header( '  Progress', $progress . '%' ),
            App::bif::show::_header(
                '  Tasks', "$at open, $st stalled, $rt closed, $it ignored"
            ),

            # TODO "Updated:..."
            App::bif::show::_header(
                '  Issues', "$ai open, $si stalled, $ri closed, $ii ignored"
            ),

            # TODO "Updated:..."
            App::bif::show::_header(
                '  Updated',
                App::bif::show::_new_ago( $ref->{mtime}, $ref->{mtimetz} )
            ),
        );
    }

    if ( $ctx->{full} ) {
        require Text::Autoformat;
        push(
            @data,
            App::bif::show::_header(
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
    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    $ctx->end_pager;

    return $ctx->ok( 'ShowProject', \@data );
}

1;
__END__

=head1 NAME

bif-show-project - display a project's current status

=head1 VERSION

0.1.0_25 (2014-06-14)

=head1 SYNOPSIS

    bif show project PATH [HUB] [OPTIONS...]

=head1 DESCRIPTION

The C<bif show project> command displays a summary of a project's
current status.

    bif show project todo

    # Project:     title fdslijfdslijjfds                 
    #   Path:      todo <529ccc29>                        
    #   Hub:       hub </home/mark/src/bif/hub>           
    #   Phases:    define, plan, RUN, eval, closed        
    #   Progress:  0%                                     
    #   Tasks:     1 open, 0 stalled, 0 closed, 0 ignored 
    #   Issues:    1 open, 0 stalled, 0 closed, 0 ignored 
    #   Updated:   3 days ago <Sun 2014-05-04 21:44 +0200>

=head1 ARGUMENTS & OPTIONS

=over

=item PATH

A project path or ID. Required. By default only local projects are
looked up in the database.

=item HUB

An optional hub name or location to look for matches.

=item --full, -f

Display a more verbose version of the current status.

=item --uuid, -u

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

