package App::bif::log;
use strict;
use warnings;
use App::bif::Util;
use Text::Autoformat qw/autoformat/;
use locale;

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

    $NOW = time;

    require POSIX;
    require Term::ANSIColor;
    require Time::Piece;
    require Time::Duration;

    $bold   = Term::ANSIColor::color('bold');
    $yellow = Term::ANSIColor::color('yellow');
    $dark   = Term::ANSIColor::color('dark');
    $reset  = Term::ANSIColor::color('reset');
    $white  = Term::ANSIColor::color('white');

    if ( $opts->{id} ) {
        my $info =
             $db->get_topic( $opts->{id} )
          || $db->get_project( $opts->{id} )
          || bif_err( 'TopicNotFound', 'topic not found: ' . $opts->{id} );

        my $func = __PACKAGE__->can( '_log_' . $info->{kind} )
          || bif_err( 'LogUnimplemented',
            'cannnot log type: ' . $info->{kind} );

        return $func->( $db, $info );
    }

    my $sth = $db->xprepare(
        select => [
            'COALESCE(projects.path,topics.id) AS topic_id',
            'topics.uuid AS topic_uuid',
            'updates.id',
            'updates.uuid',
            'updates.mtime',
            'updates.mtimetz',
            'updates.author',
            'updates.email',
            'updates.message',
            'updates.id = topics.first_update_id AS new_item',
            "GROUP_CONCAT(
                topics.kind
            , '\n') AS kind",
            "GROUP_CONCAT(
                COALESCE(
                    COALESCE(issue_updates.title, issues.title),
                    COALESCE(task_updates.title, tasks.title),
                    COALESCE(project_updates.title, projects.title)
                )
            , '\n') AS title",
        ],
        from      => 'updates',
        left_join => 'project_updates',
        on        => 'project_updates.update_id = updates.id AND
                      project_updates.new IS NULL',
        left_join => 'projects',
        on        => 'projects.id = project_updates.project_id',
        left_join => 'task_updates',
        on        => 'task_updates.update_id = updates.id',
        left_join => 'tasks',
        on        => 'tasks.id = task_updates.task_id',
        left_join => 'issue_updates',
        on        => 'issue_updates.update_id = updates.id',
        left_join => 'issues',
        on        => 'issues.id = issue_updates.issue_id',
        left_join => 'topics',
        on        => 'topics.id = project_updates.project_id OR
                       topics.id = task_updates.task_id OR
                       topics.id = issue_updates.issue_id',
        do {
            my $where_cond = '';

            foreach my $filter ( @{ $opts->{filter} } ) {

                # This could be much more efficently done with a
                # completely different query that inner joins
                # topics.first_update_id with updates. But for now...
                if ( $filter eq 'new' ) {
                    $where_cond .= ' OR' if $where_cond;
                    $where_cond .= ' updates.id = topics.first_update_id';
                }
                elsif ( $filter eq 'status' ) {
                    $where_cond .= ' OR' if $where_cond;
                    $where_cond .=
                        ' (project_updates.status_id IS NOT NULL '
                      . 'OR task_updates.status_id IS NOT NULL '
                      . 'OR issue_updates.status_id IS NOT NULL)';
                }
                else {
                    bif_err( 'InvalidFilter',
                        'not a valid --filter: ' . $filter );
                }
            }

            if ($where_cond) {
                ( where => $where_cond );
            }
            else {
                ();
            }
        },
        group_by => [
            'updates.id',      'updates.uuid',
            'updates.mtime',   'updates.mtimetz',
            'updates.author',  'updates.email',
            'updates.message', 'updates.id = topics.first_update_id',
        ],
        order_by => [ 'updates.mtime desc', 'updates.uuid', ],
    );

    $sth->execute;

    start_pager;

    while ( my $row = $sth->hash ) {
        my @data;

        if ( $row->{new_item} ) {

 #            push( @data,
 #                _header( $yellow . ucfirst( $row->{kind} ), $row->{title} ) );
            push(
                @data,
                _header(
                    $yellow . $row->{kind},
                    $yellow . $row->{topic_id},
                    $row->{topic_uuid}
                )
            );
        }
        else {
            push(
                @data,
                _header(
                    $dark . $yellow . 'comment',
                    $dark . $yellow . "$row->{topic_id}.$row->{id}",
                    $row->{uuid}
                )
            );
        }

        push( @data, _header( 'From', $row->{author}, $row->{email} ) );

        push( @data,
            _header( 'When', _new_ago( $row->{mtime}, $row->{mtimetz} ) ) );

        #        if (!$row->{new_item}) {
        push(
            @data,
            _header(
                'Subject',
                ( $row->{new_item} ? '' : "Re: [$row->{kind}] " )
                  . $row->{title},
            )
        );

        #        }

        print render_table( 'l  l', undef, \@data ) . "\n";

        if ( $row->{push_to} ) {
            print "[Pushed to " . $row->{push_to} . "]\n\n\n";
        }
        else {
            print _reformat( $row->{message} ), "\n";
        }
        next;

    }
    end_pager;
    return 'Log';
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

sub _reformat {
    my $text = shift;
    my $depth = shift || 0;

    $depth-- if $depth;

    my $left   = 1 + 4 * $depth;
    my $indent = '    ' x $depth;

    my @result;

    foreach my $para ( split /\n\n/, $text ) {
        if ( $para =~ m/^[^\s]/ ) {
            push( @result, autoformat( $para, { left => $left } ) );
        }
        else {
            $para =~ s/^/$indent/gm;
            push( @result, $para, "\n\n" );
        }
    }

    return @result;
}

my $title;
my $path;

sub _log_item {
    my $row  = shift;
    my $type = shift;

    $title = $row->{title};
    $path  = $row->{path};

    my @data = (
        _header( $yellow . $type, $yellow . $row->{id}, $row->{update_uuid} ),
        _header( 'From',          $row->{author},       $row->{email} ),
        _header( 'When',    _new_ago( $row->{mtime}, $row->{mtimetz} ) ),
        _header( 'Subject', "[$row->{path}] $row->{title}" )
    );

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, _header(@$field) );
    }

    print render_table( 'l  l', undef, \@data ) . "\n";
    print _reformat( $row->{message} ), "\n";

    return;
}

sub _log_comment {
    my $row = shift;
    my @data;

    push(
        @data,
        _header(
            $dark . $yellow . ( $row->{depth} > 1 ? 'reply' : 'update' ),
            $dark . $yellow . $row->{update_id},
            $row->{update_uuid}
        ),
        _header( 'From', $row->{author},          $row->{email} ),
        _header( 'When', _new_ago( $row->{mtime}, $row->{mtimetz} ) ),
    );

    $path = $row->{path} if $row->{path};

    if ( $row->{title} ) {
        $title = $row->{title} if $row->{title};
        push( @data, _header( 'Subject', "[$path] $title" ) );
    }
    else {
        push( @data, _header( 'Subject', "Re: [$path] $title" ) );
    }

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, _header(@$field) );
    }

    print render_table( 'l  l', undef, \@data, 4 * ( $row->{depth} - 1 ) )
      . "\n";

    if ( $row->{push_to} ) {
        print "[Pushed to " . $row->{push_to} . "]\n\n\n";
    }
    else {
        print _reformat( $row->{message}, $row->{depth} ), "\n";
    }
}

sub _log_task {
    my $db   = shift;
    my $info = shift;

    my $sth = $db->xprepare(
        select => [
            'task_updates.task_id AS id',
            "task_updates.task_id ||'.' || task_updates.update_id AS update_id",
            'updates.uuid AS update_uuid',
            'task_updates.title',
            'updates.mtime',
            'updates.mtimetz',
            'updates.author',
            'updates.email',
            'task_status.status',
            'task_status.status',
            'projects.path',
            'projects.title AS project_title',
            'updates_tree.depth',
            'updates.message',
        ],
        from       => 'task_updates',
        inner_join => 'updates',
        on         => 'updates.id = updates_tree.child',
        left_join  => 'task_status',
        on         => 'task_status.id = task_updates.status_id',
        left_join  => 'projects',
        on         => 'projects.id = task_status.project_id',
        inner_join => 'updates_tree',
        on         => {
            'updates_tree.parent' => $info->{first_update_id},
            'updates_tree.child'  => \'task_updates.update_id'
        },
        where    => { 'task_updates.task_id' => $info->{id} },
        order_by => 'updates.path ASC',
    );

    $sth->execute;

    start_pager;

    _log_item( scalar $sth->hash, 'task' );
    _log_comment($_) for $sth->hashes;

    end_pager;
    return 'LogTask';
}

sub _log_issue {
    my $db   = shift;
    my $info = shift;

    DBIx::ThinSQL->import(qw/concat case qv/);
    my $sth = $db->xprepare(
        select => [
            'project_issues.issue_id AS "id"',
            'updates.uuid',
            concat( 'project_issues.id', qv('.'), 'updates.id' )
              ->as('update_id'),
            'updates.uuid AS update_uuid',
            'updates.mtime',
            'updates.mtimetz',
            'updates.author',
            'updates.email',
            'updates.message',
            'issue_status.status',
            'issue_status.status',
            'issue_updates.new',
            'issue_updates.title',
            'projects.path',
            'updates_tree.depth',
        ],
        from       => 'issue_updates',
        inner_join => 'updates',
        on         => 'updates.id = issue_updates.update_id',
        inner_join => 'projects',
        on         => 'projects.id = issue_updates.project_id',
        inner_join => 'project_issues',
        on         => {
            'project_issues.project_id' => \'issue_updates.project_id',
            'project_issues.issue_id'   => \'issue_updates.issue_id',
        },
        left_join  => 'issue_status',
        on         => 'issue_status.id = issue_updates.status_id',
        inner_join => 'updates_tree',
        on         => {
            'updates_tree.child'  => \'updates.id',
            'updates_tree.parent' => $info->{first_update_id}
        },
        where    => { 'issue_updates.issue_id' => $info->{id} },
        order_by => 'updates.path ASC',
    );

    $sth->execute;

    start_pager;

    _log_item( scalar $sth->hash, 'issue' );
    _log_comment($_) for $sth->hashes;

    end_pager;
    return 'LogIssue';
}

sub _log_project {
    my $db   = shift;
    my $info = shift;

    my $sth = $db->xprepare(
        select => [
            'project_updates.project_id AS id',
            "project_updates.project_id ||'.' || updates.id AS update_id",
            'updates.uuid AS update_uuid',
            'project_updates.title',
            'updates.mtime',
            'updates.mtimetz',
            'updates.author',
            'updates.email',
            'updates.message',
            'updates_tree.depth',
            'project_status.status',
            'project_status.status',
            'projects.path',
            'project_updates.name',
        ],
        from       => 'project_updates',
        inner_join => 'projects',
        on         => 'projects.id = project_updates.project_id',
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        inner_join => 'updates_tree',
        on         => 'updates_tree.parent = topics.first_update_id AND
                       updates_tree.child = project_updates.update_id',
        inner_join => 'updates',
        on         => 'updates.id = updates_tree.child',
        left_join  => 'project_status',
        on         => 'project_status.id = project_updates.status_id',
        where      => {
            'project_updates.project_id' => $info->{id},
            'project_updates.new'        => undef,
        },
        order_by => 'updates.path asc',
    );

    $sth->execute;

    start_pager;

    my $first = $sth->hash;
    _log_item( $first, 'project', [ 'Phase', $first->{status} ] );
    _log_comment( $_, [ 'Phase', $_->{status} ] ) for $sth->hashes;

    end_pager;
    return 'LogProject';
}

1;
__END__

=head1 NAME

bif-log - review the repository or topic history

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif log [ID] [OPTIONS...]

=head1 DESCRIPTION

Display the history of changes in the repository in reverse
chronological order.

=head1 ARGUMENTS

=over

=item ID

A topic ID or a project PATH. If this argument is used then only the
history from that topic will be displayed, in hierarchical
(conversation topic) order.

=back

=head1 OPTIONS

=over

=item --filter TYPE

Only show entries of a specific TYPE:

=over

=item * new

Entries related to topic creation.

=item * status

Entries related to topic status changes. Note that this option will
include the entries from the 'new' filter.

=back

Can be used multiple times to filter on multiple types.

=item --format STYLE

[Not Implemented] Change the amount of detail displayed for each entry.
STYLE can be one of the following:

=over

=item * short

=item * normal

=item * full

=back

=item --group TIMESPAN

[Not Implemented] Group the entries together based on one of the
following TIMESPANs:

=over

=item * hour

=item * day

=item * week

=item * month

=item * logtime

Group the entries into blocks of activity that happened in the last
hour, today, yesterday, last week, etc.

=back

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

