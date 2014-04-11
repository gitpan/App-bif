package App::bif::show;
use strict;
use warnings;
use App::bif::Context;

our $VERSION = '0.1.0_5';

my $NOW;
my $bold;
my $yellow;
my $dark;
my $reset;
my $white;

sub run {
    my $ctx = App::bif::Context->new(shift);

    if ( $ctx->{id} eq 'VERSION' ) {
        require App::bif::Version;
        print "$App::bif::Version::VERSION "
          . "($App::bif::Version::BRANCH) "
          . "$App::bif::Version::COMMIT "
          . "($App::bif::Version::DATE)\n";
        return $ctx->ok('ShowVersion');
    }
    elsif ( $ctx->{uuid} ) {
        my $uuid = $ctx->{id};
        $ctx->{id} = $ctx->db->uuid2id( $ctx->{id} )
          || return $ctx->err( 'UuidNotFound', "uuid not found: $uuid" );
    }

    my $db   = $ctx->db();
    my $info = $db->get_topic( $ctx->{id} )
      || $db->get_project( $ctx->{id}, $ctx->{hub} );

    if ( !$info && defined $info && $info < 0 ) {
        return $ctx->err(
            'AmbiguousID', "non-specific identifier:
      $ctx->{id}"
        );
    }

    return $ctx->err( 'TopicNotFound', 'topic not found: ' . $ctx->{id} )
      unless $info;

    my $func = __PACKAGE__->can( '_show_' . $info->{kind} )
      || return $ctx->err( 'ShowUnimplemented',
        'cannnot show type: ' . $info->{kind} );

    return $ctx->err( 'ShowNoUpdates', 'cannot show an update ID' )
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

    return $func->( $ctx, $db, $info );
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
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum case coalesce concat qv/);

    my $ref = $db->xhash(
        select => [
            'topics.id',
            'topics.uuid',
            'projects.path',
            'projects.title',
            'topics.ctime',
            'topics.ctimetz',
            'topics.mtime',
            'topics.mtimetz',
            'updates.author',
            'updates.email',
            'updates.message',
            'project_status.status',
            'project_status.status',
            case (
                when => 'rp.repo_id IS NOT NULL',
                then => 1,
                else => qv(undef),
              )->as('local'),
            'r2.alias AS hub',
            't2.uuid AS hub_uuid',
        ],
        from       => 'projects',
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        inner_join => 'updates',
        on         => 'updates.id = topics.first_update_id',
        inner_join => 'project_status',
        on         => 'project_status.id = projects.status_id',
        inner_join => 'repos r',
        on         => 'r.local = 1',
        left_join  => 'repo_projects rp',
        on         => 'rp.repo_id = r.id AND rp.project_id = projects.id',
        left_join  => 'repos r2',
        on         => 'r2.id = projects.repo_id',
        left_join  => 'topics t2',
        on         => 't2.id = r2.id',
        where      => { 'projects.id' => $info->{id} },
    );

    push(
        @data,
        _header(
            $yellow . 'Project',
            $yellow . $ref->{title}
        ),

        _header( '  ID',   $ref->{id}, $ref->{uuid} ),
        _header( '  Path', $ref->{path} ),
    );

    push( @data, _header( '  Hub', $ref->{hub}, $ref->{hub_uuid} ), )
      if $ref->{hub};

    if ( $ctx->{full} ) {
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
        push( @data, _header( '  Phase', $ref->{status} ), );
    }

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
            _header( '  Progress', $progress . '%' ),
            _header(
                '  Tasks', "$at open, $st stalled, $rt closed, $it ignored"
            ),

            # TODO "Updated:..."
            _header(
                '  Issues', "$ai open, $si stalled, $ri closed, $ii ignored"
            ),

            # TODO "Updated:..."
            _header( '  Updated', _new_ago( $ref->{mtime}, $ref->{mtimetz} ) ),
        );
    }

    if ( $ctx->{full} ) {
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
    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    $ctx->end_pager;

    $ctx->ok( 'ShowProject', \@data );
}

sub _show_task {
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum qv concat/);

    my $ref = $db->xhash(
        select => [
            'topics.id AS id',
            'topics.uuid',
            concat( 'projects.path', qv('@'), 'r.alias' )->as('path'),
            'topics2.uuid AS project_uuid',
            'tasks.title AS title',
            'topics.mtime AS mtime',
            'topics.mtimetz AS mtimetz',
            'topics.ctime AS ctime',
            'topics.ctimetz AS ctimetz',
            'updates.author AS author',
            'updates.email AS email',
            'updates.message AS message',
            'task_status.status AS status',
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
        inner_join => 'repo_projects rp',
        on         => 'rp.project_id = projects.id',
        inner_join => 'repos r',
        on         => 'r.id = rp.repo_id',
        inner_join => 'topics AS topics2',
        on         => 'topics2.id = projects.id',
        inner_join => 'updates AS updates2',
        on         => 'updates2.id = tasks.update_id',
        where      => [ 'topics.id = ', qv( $info->{id} ) ],
    );

    my @ago = _new_ago( $ref->{smtime}, $ref->{mtimetz} );

    push( @data,
        _header( $yellow . 'Task', $yellow . $ref->{title} ),
        _header( '  ID',      "$ref->{id}", $ref->{uuid} ),
        _header( '  Project', $ref->{path}, $ref->{project_uuid} ),
        _header( '  Status', "$ref->{status} (" . $ago[0] . ')', $ago[1] ),
    );

    if ( $ctx->{full} ) {
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
        _header( '  Updated', _new_ago( $ref->{mtime}, $ref->{mtimetz} ) ),
    );

    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    $ctx->end_pager;

    $ctx->ok( 'ShowTask', \@data );
}

sub _show_issue {
    my $ctx  = shift;
    my $db   = shift;
    my $info = shift;
    my @data;

    DBIx::ThinSQL->import(qw/sum qv lower func concat/);

    my @refs = $db->xhashes(
        select => [
            'project_issues.id AS id',
            'topics.uuid',
            concat( 'projects.path', qv('@'), 'r.alias' )->as('path'),
            'projects.title AS project_title',
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
        inner_join => 'repo_projects rp',
        on         => 'rp.project_id = projects.id',
        inner_join => 'repos r',
        on         => 'r.id = rp.repo_id',
        inner_join => 'topics AS topics2',
        on         => 'topics2.id = projects.id',
        inner_join => 'issue_status',
        on         => 'issue_status.id = project_issues.status_id',
        inner_join => 'updates AS updates2',
        on         => 'updates2.id = project_issues.update_id',
        where      => { 'topics.id' => $info->{id} },
        order_by   => [
            "project_issues.id = $info->{project_issue_id} DESC",
            "r.local ASC",
            "updates2.mtime ASC",
        ],
    );

    push( @data, _header( $yellow . 'Issue', $yellow . $refs[0]->{title} ), );

    my %seen;
    my $count = @refs;
    my $i     = 1;
    foreach my $ref (@refs) {
        if ( !$seen{ $ref->{id} }++ ) {
            my @ago = _new_ago( $ref->{smtime}, $ref->{mtimetz} );
            push(
                @data,
                _header( '  Project', $ref->{path}, $ref->{project_uuid} ),
                _header( '  ID',      $ref->{id},   $ref->{uuid} ),
                _header(
                    '  Status', "$ref->{status} (" . $ago[0] . ')',
                    $ago[1]
                ),
                _header(
                    '  Updated',
                    _new_ago( $refs[0]->{mtime}, $refs[0]->{mtimetz} )
                ),
            );
        }
        push( @data, [ '  .', ' ' ] ) if $i++ < $count,;
    }

    $ctx->start_pager;
    print $ctx->render_table( 'l  l', undef, \@data );
    print "\n" . $refs[0]->{message} if ( $ctx->{full} );

    $ctx->end_pager;

    $ctx->ok( 'ShowIssue', \@data );
}

1;
__END__

=head1 NAME

bif-show - display a item's current status

=head1 VERSION

0.1.0_5 (2014-04-11)

=head1 SYNOPSIS

    bif show ID [OPTIONS...]

=head1 DESCRIPTION

The C<bif show> command displays a summary of a topic's current status.
The output varies depending on the type of topic.

When the uppercase string "VERSION" is given as the ID then this
command will print the bif version string plus the Git branch and Git
commit from which bif was built.

=head1 ARGUMENTS

=over

=item ID

A topic ID or a project PATH. Required.

=back

=head1 OPTIONS

=over

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

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

