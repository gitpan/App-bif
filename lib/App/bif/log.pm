package App::bif::log;
use strict;
use warnings;
use App::bif::Context;
use Text::Autoformat qw/autoformat/;
use locale;

our $VERSION = '0.1.0_23';

our $NOW;
our $bold;
our $yellow;
our $dark;
our $reset;
our $white;

sub init {
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
}

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->db();

    init();

    if ( $ctx->{id} ) {
        my $info = $ctx->get_topic( $ctx->{id} );

        my $func = __PACKAGE__->can( '_log_' . $info->{kind} )
          || return $ctx->err( 'LogUnimplemented',
            'cannnot log type: ' . $info->{kind} );

        return $func->( $ctx, $info );
    }

    return _log_hub( $ctx, $ctx->get_topic( $db->get_local_hub_id ) );

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
    my $ctx  = shift;
    my $row  = shift;
    my $type = shift;

    $title = $row->{title};
    $path  = $row->{path};

    ( my $id = $row->{update_id} ) =~ s/(.+)\./$yellow$1$dark\./;
    my @data = (
        _header( $yellow . $type, $id,            $row->{update_uuid} ),
        _header( 'From',          $row->{author}, $row->{email} ),
        _header( 'When', _new_ago( $row->{mtime}, $row->{mtimetz} ) ),
    );

    if ( $row->{status} ) {
        push(
            @data,
            _header(
                'Subject', "[$row->{path}][$row->{status}] $row->{title}"
            )
        );
    }
    else {
        push( @data, _header( 'Subject', "[$row->{path}] $row->{title}" ) );
    }

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, _header(@$field) );
    }

    print $ctx->render_table( 'l  l', undef, \@data ) . "\n";
    print _reformat( $row->{message} ), "\n";

    return;
}

sub _log_comment {
    my $ctx = shift;
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
    elsif ( $row->{status} ) {
        push( @data,
            _header( 'Subject', "[$path][$row->{status}] Re: $title" ) );
    }
    else {
        push( @data, _header( 'Subject', "[$path] Re: $title" ) );
    }

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, _header(@$field) );
    }

    print $ctx->render_table( 'l  l', undef, \@data, 4 * ( $row->{depth} - 1 ) )
      . "\n";

    if ( $row->{push_to} ) {
        print "[Pushed to " . $row->{push_to} . "]\n\n\n";
    }
    else {
        print _reformat( $row->{message}, $row->{depth} ), "\n";
    }
}

sub _log_hub {
    my $ctx  = shift;
    my $db   = $ctx->db;
    my $info = shift;

    my $sth = $db->xprepare(
        select => [
            q{strftime('%w',u.mtime,'unixepoch','localtime') AS weekday},
            q{strftime('%Y-%m-%d',u.mtime,'unixepoch','localtime') AS mdate},
            q{strftime('%H:%M:%S',u.mtime,'unixepoch','localtime') AS mtime},
            'u.message',
        ],
        from       => 'hub_deltas hd',
        inner_join => 'updates u',
        on         => 'u.id = hd.update_id',
        where      => { 'hd.hub_id' => $info->{id} },
        group_by   => [qw/weekday mdate mtime/],
        order_by   => 'u.id DESC',
    );

    $sth->execute;

    $ctx->start_pager;

    my @days = (
        qw/Sunday Monday Tuesday Wednesday Thursday Friday
          Saturday/
    );

    my $first   = $sth->array;
    my $weekday = $first->[0];

    print " $dark$first->[1] ($days[$weekday]) $reset \n";
    print '-' x 80, "\n";
    print " $first->[2]  $first->[3]\n";

    while ( my $n = $sth->array ) {
        if ( $n->[0] != $weekday ) {
            print "\n $dark$n->[1] ($days[ $n->[0] ])$reset\n";
            print '-' x 80, "\n";
        }

        print " $n->[2]  $n->[3]\n";
        $weekday = $n->[0];
    }

    $ctx->end_pager;
    return $ctx->ok('LogRepo');
}

sub _log_task {
    my $ctx  = shift;
    my $db   = $ctx->db;
    my $info = shift;

    my $sth = $db->xprepare(
        select => [
            'task_deltas.task_id AS id',
            "task_deltas.task_id ||'.' || task_deltas.update_id AS update_id",
            'updates.uuid AS update_uuid',
            'task_deltas.title',
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
        from       => 'task_deltas',
        inner_join => 'updates',
        on         => 'updates.id = updates_tree.child',
        left_join  => 'task_status',
        on         => 'task_status.id = task_deltas.status_id',
        left_join  => 'projects',
        on         => 'projects.id = task_status.project_id',
        inner_join => 'updates_tree',
        on         => {
            'updates_tree.parent' => $info->{first_update_id},
            'updates_tree.child'  => \'task_deltas.update_id'
        },
        where    => { 'task_deltas.task_id' => $info->{id} },
        order_by => 'updates.path ASC',
    );

    $sth->execute;

    $ctx->start_pager;

    _log_item( $ctx, scalar $sth->hash, 'task' );
    _log_comment( $ctx, $_ ) for $sth->hashes;

    $ctx->end_pager;
    return $ctx->ok('LogTask');
}

sub _log_issue {
    my $ctx  = shift;
    my $db   = $ctx->db;
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
            'updates.ucount',
            'issue_status.status',
            'issue_status.status',
            'issue_deltas.new',
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

    $ctx->start_pager;

    _log_item( $ctx, scalar $sth->hash, 'issue' );

    while ( my $row = $sth->hash ) {
        my @data;
        push(
            @data,
            _header(
                $dark . $yellow . ( $row->{depth} > 1 ? 'reply' : 'update' ),
                $dark . $yellow . $row->{update_id},
                $row->{update_uuid}
            ),
        );

        my @r = ($row);
        if ( $row->{ucount} > 2 ) {
            for my $i ( 1 .. ( $row->{ucount} - 2 ) ) {
                my $r = $sth->hash;
                push(
                    @data,
                    _header(
                        $dark
                          . $yellow
                          . ( $r->{depth} > 1 ? 'reply' : 'update' ),
                        $dark . $yellow . $r->{update_id},
                        $r->{update_uuid}
                    ),
                );
                push( @r, $r );
            }
        }

        push( @data,
            _header( 'From', $row->{author},          $row->{email} ),
            _header( 'When', _new_ago( $row->{mtime}, $row->{mtimetz} ) ),
        );

        my $i;
        foreach my $row (@r) {
            $path = $row->{path} if $row->{path};

            if ( $row->{title} ) {
                $title = $row->{title} if $row->{title};
                push( @data, _header( 'Subject', "[$path] $title" ) );
            }
            elsif ( $row->{status} ) {
                push( @data,
                    _header( 'Subject', "[$path][$row->{status}] Re: $title" )
                );
            }
            else {
                push( @data, _header( 'Subject', "[$path] Re: $title" ) );
            }

        }

        $row = pop @r;

        print $ctx->render_table( 'l  l', undef, \@data,
            4 * ( $row->{depth} - 1 ) )
          . "\n";

        print _reformat( $row->{message}, $row->{depth} ), "\n";

    }

    $ctx->end_pager;
    return $ctx->ok('LogIssue');
}

sub _log_project {
    my $ctx  = shift;
    my $db   = $ctx->db;
    my $info = shift;

    my $sth = $db->xprepare(
        select => [
            'project_deltas.project_id AS id',
            "project_deltas.project_id ||'.' || updates.id AS update_id",
            'updates.uuid AS update_uuid',
            'project_deltas.title',
            'updates.mtime',
            'updates.mtimetz',
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
        inner_join => 'topics',
        on         => 'topics.id = projects.id',
        inner_join => 'updates_tree',
        on         => 'updates_tree.parent = topics.first_update_id AND
                       updates_tree.child = project_deltas.update_id',
        inner_join => 'updates',
        on         => 'updates.id = updates_tree.child',
        left_join  => 'project_status',
        on         => 'project_status.id = project_deltas.status_id',
        where      => {
            'project_deltas.project_id' => $info->{id},

            #            'project_deltas.new'        => undef,
        },
        order_by => 'updates.path asc',
    );

    $sth->execute;

    $ctx->start_pager;

    my $first = $sth->hash;
    _log_item( $ctx, $first, 'project', [ 'Phase', $first->{status} ] );
    _log_comment( $ctx, $_ ) for $sth->hashes;

    $ctx->end_pager;
    return $ctx->ok('LogProject');
}

1;
__END__

=head1 NAME

bif-log - review the repository or topic history

=head1 VERSION

0.1.0_23 (2014-06-04)

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

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

