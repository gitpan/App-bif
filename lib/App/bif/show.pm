package App::bif::show;
use strict;
use warnings;
use App::bif::Util;

our $VERSION = '0.1.0';

my $NOW;
my $bold;
my $yellow;
my $dark;
my $reset;
my $white;

sub run {
    my $opts = bif_init(shift);
    my $db   = bif_db();

    my $info =
         $db->get_topic( $opts->{id} )
      || $db->get_project( $opts->{id} )
      || bif_err( 'TopicNotFound', 'topic not found: ' . $opts->{id} );

    my $func = __PACKAGE__->can( '_show_' . $info->{kind} )
      || bif_err( 'ShowUnimplemented', 'cannnot show type: ' . $info->{kind} );

    bif_err( 'ShowNoUpdates', 'cannot show an update ID' )
      if exists $info->{update_id};

    $NOW = time;
    require POSIX;
    require Term::ANSIColor;
    require Time::Piece;
    require Time::Duration;

    $bold   = Term::ANSIColor::color('bold');
    $yellow = Term::ANSIColor::color('bold');
    $dark   = Term::ANSIColor::color('dark');
    $reset  = Term::ANSIColor::color('reset');
    $white  = Term::ANSIColor::color('white');

    return $func->( $opts, $db, $info );
}

sub _header {
    return [
        ( $_[0] ? $_[0] . ':' : '' ) . $reset,
        $_[1] . ( defined $_[2] ? $dark . ' <' . $_[2] . '>' : '' ) . $reset
    ];
}

sub _new_ago {
    use locale;

    my $time    = shift;
    my $offset  = shift;
    my $hours   = POSIX::floor( $offset / 60 / 60 );
    my $minutes = ( abs($offset) - ( abs($hours) * 60 * 60 ) ) / 60;
    my $dt      = Time::Piece->strptime( $time + $offset, '%s' );

    my $local =
      sprintf( '%s %+.2d%.2d', $dt->strftime('%a %F %R'), $hours, $minutes );

    return ( Time::Duration::ago( $NOW - $time, 1 ), $local );
}

sub _show_project {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce/);

    my $ref = $db->xhash(
        select => [
            'topics.id',       'topics.uuid',
            'projects.path',   'projects.title',
            'topics.ctime',    'topics.ctimetz',
            'topics.mtime',    'topics.mtimetz',
            'updates.author',  'updates.email',
            'updates.message', 'project_status.status',
            'project_status.status',
        ],
        from       => 'projects',
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        inner_join => 'updates',
        on         => 'updates.id = topics.first_update_id',
        inner_join => 'project_status',
        on         => 'project_status.id = projects.status_id',
        where      => { 'projects.id' => $info->{id} },
    );

    push(
        @data,
        _header(
            $yellow . 'Project',
            $yellow . '[' . $ref->{path} . '] ' . $ref->{title}
        ),

        #        _header( '  Title',           $ref->{title} ),
    );

    if ( $opts->{full} ) {
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

        push( @data,
            _header( '  Creator', $ref->{author},          $ref->{email} ),
            _header( '  Created', _new_ago( $ref->{ctime}, $ref->{ctimetz} ) ),
            _header( '  Phases', join( ', ', map { $_->[0] } @phases ) ),
        );
    }
    else {
        push( @data, _header( 'Phase', $ref->{status} ), );
    }

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
        _header( 'Progress', $progress . '%' ),
        _header(
            'Tasks', "$at open, $st stalled, $rt closed, $it ignored"
        ),

        # TODO "Updated:..."
        _header( 'Issues', "$ai open, $si stalled, $ri closed, $ii ignored" ),

        # TODO "Updated:..."
        _header( 'Updated', _new_ago( $ref->{mtime}, $ref->{mtimetz} ) ),
    );

    if ( $opts->{full} ) {
        require Text::Autoformat;
        push(
            @data,
            _header(
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
    start_pager;
    print render_table( 'l  l', undef, \@data );
    end_pager;

    return bif_ok( 'ShowProject', \@data );
}

sub _show_task {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum qv concat/);

    my $ref = $db->xhash(
        select => [
            'topics.id AS id',
            'topics.uuid',
            'projects.path AS path',
            'topics2.uuid AS project_uuid',
            'tasks.title AS title',
            'topics.mtime AS mtime',
            'topics.mtimetz AS mtimetz',
            'topics.ctime AS ctime',
            'topics.ctimetz AS ctimetz',
            'updates.author AS author',
            'updates.email AS email',
            'updates.message AS message',
q{task_status.status || ' (' || task_status.status || ')' AS status},
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
        inner_join => 'topics AS topics2',
        on         => 'topics2.id = projects.id',
        inner_join => 'updates AS updates2',
        on         => 'updates2.id = tasks.update_id',
        where      => [ 'topics.id = ', qv( $info->{id} ) ],
    );

    push( @data,
        _header( $yellow . 'task', $yellow . $ref->{id},    $ref->{uuid} ),
        _header( 'From',           $ref->{author},          $ref->{email} ),
        _header( 'When',           _new_ago( $ref->{ctime}, $ref->{ctimetz} ) ),
        _header( 'Subject',        $ref->{title} . "\n" ),
    );

    my @ago = _new_ago( $ref->{smtime}, $ref->{mtimetz} );
    push(
        @data,
        _header(
            $dark . $yellow . 'project',
            $dark . $yellow . $ref->{path},
            $ref->{project_uuid}
        ),
        _header( 'Status', $ref->{status} . ' ' . $ago[0], $ago[1] ),
    );

    if ( $opts->{full} ) {
        require Text::Autoformat;
        push(
            @data,
            _header(
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

    push( @data,
        _header( 'Updated', _new_ago( $ref->{mtime}, $ref->{mtimetz} ) ),
    );

    start_pager;
    print render_table( 'l  l', undef, \@data );
    end_pager;

    return bif_ok( 'ShowTask', \@data );
}

sub _show_issue {
    my $opts = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum qv lower func concat/);

    my @refs = $db->xhashes(
        select => [
            'project_issues.id AS id',
            'topics.uuid',
            'projects.path AS path',
            'topics2.uuid AS project_uuid',
            'issues.title AS title',
            'topics.mtime AS mtime',
            'topics.mtimetz AS mtimetz',
            'topics.ctime AS ctime',
            'topics.ctimetz AS ctimetz',
            'updates.author AS author',
            'updates.email AS email',
            'updates.message AS message',
            concat(
                'issue_status.status',    # qv(' ('),

                #                'issue_status.status', qv(')')
              )->as('status'),
            'updates2.mtime AS smtime',
        ],
        from       => 'topics',
        inner_join => 'issues',
        on         => 'issues.id = topics.id',
        inner_join => 'updates',
        on         => 'updates.id = topics.first_update_id',
        inner_join => 'project_issues',
        on         => 'project_issues.issue_id = topics.id',
        inner_join => 'projects',
        on         => 'projects.id = project_issues.project_id',
        inner_join => 'topics AS topics2',
        on         => 'topics2.id = projects.id',
        inner_join => 'issue_status',
        on         => 'issue_status.id = project_issues.status_id',
        inner_join => 'updates AS updates2',
        on         => 'updates2.id = project_issues.update_id',
        where      => { 'topics.id' => $info->{id} },
        order_by   => "project_issues.id = $info->{project_issue_id}
        DESC, updates2.mtime ASC",    #' =>

        #        $info->{project_issue_id}}, 'updates2.mtime ASC' ],
    );

    push(
        @data,
        _header(
            $yellow . 'Issue',
            $yellow

              #              . $refs[0]->{id} . ' - ['
              #              . $refs[0]->{path} . '] '
              #              . $refs[0]->{title}
              #              . $refs[0]->{id}
              #              . '['
              #              . $refs[0]->{path}
              #              . '] '
              . $refs[0]->{id} . ' - '
              . $refs[0]->{title}
        ),
    );

    my $ref = $refs[0];

    my @ago = _new_ago( $refs[0]->{smtime}, $refs[0]->{mtimetz} );
    push(
        @data,
        _header(
            '  Status', "$ref->{status} [$ref->{path}] (" . $ago[0] . ')',
            $ago[1]
        ),
    );

    my $first = shift @refs;

    my $count = @refs;
    foreach my $ref (@refs) {
        my @ago = _new_ago( $ref->{smtime}, $ref->{mtimetz} );
        push(
            @data,

#            _header( 'Issue', '[' . $ref->{id} . '] '.$ref->{title}),
#            _header( $dark.'Status',$dark. $ref->{status} . ' ' . $ago[0], $ago[1] ),
#        _header( '  Status', "[$ref->{path}] $ref->{status} (".  $ago[0].')', $ago[1] ),
            _header(
                '  Status', "$ref->{status} [$ref->{path}] (" . $ago[0] . ')',
                $ago[1]
            ),
        );
    }

    push(
        @data,

     #        _header( 'From', $first->{author},          $first->{email} ),
     #        _header( 'When', _new_ago( $first->{ctime}, $first->{ctimetz} ) ),

        _header(
            '  Updated', _new_ago( $refs[0]->{mtime}, $refs[0]->{mtimetz} )
        ),

        #        _header( 'Subject', $refs[0]->{title} . "\n" ),
    );

    start_pager;
    print render_table( 'l  l', undef, \@data );
    print "\n" . $refs[0]->{message} if ( $opts->{full} );

  #    print #"\n"
  #       render_table(
  #        'l  l', undef,
  #        [
  #            _header(
  #                'Updated', _new_ago( $refs[0]->{mtime}, $refs[0]->{mtimetz} )
  #            )
  #        ]
  #      );
    end_pager;

    return bif_ok( 'ShowIssue', \@data );
}

1;
__END__

=head1 NAME

bif-show - display a item's current status

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif show ID [OPTIONS...]

=head1 DESCRIPTION

Display a summary of a topic's current status. The output varies
depending on the type of topic.

=head1 ARGUMENTS

=over

=item ID

A topic ID or a project PATH. Required.

=back

=head1 OPTIONS

=over

=item --full, -f

Display a more verbose version of the current status.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

