package App::bif::log::issue;
use strict;
use warnings;
use App::bif::Context;
use App::bif::log;

our $VERSION = '0.1.0_24';

sub run {
    my $ctx  = App::bif::Context->new(shift);
    my $db   = $ctx->db;
    my $info = $ctx->get_topic( $ctx->{id} );

    return $ctx->err( 'TopicNotFound', "topic not found: $ctx->{id}" )
      unless $info;

    return $ctx->err( 'NotAnIssue', "not an issue ID: $ctx->{id}" )
      unless $info->{kind} eq 'issue';

    App::bif::log::init;
    my $dark   = $App::bif::log::dark;
    my $reset  = $App::bif::log::reset;
    my $yellow = $App::bif::log::yellow;

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

    my $row   = $sth->hash;
    my $title = $row->{title};

    App::bif::log::_log_item( $ctx, $row, 'issue' );

    my $path;

    while ( my $row = $sth->hash ) {
        my @data;
        push(
            @data,
            App::bif::log::_header(
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
                    App::bif::log::_header(
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

        push(
            @data,
            App::bif::log::_header( 'From', $row->{author}, $row->{email} ),
            App::bif::log::_header(
                'When',
                App::bif::log::_new_ago( $row->{mtime}, $row->{mtimetz} )
            ),
        );

        foreach my $row (@r) {
            $path = $row->{path} if $row->{path};

            if ( $row->{title} ) {
                $title = $row->{title} if $row->{title};
                push( @data,
                    App::bif::log::_header( 'Subject', "[$path] $title" ) );
            }
            elsif ( $row->{status} ) {
                push(
                    @data,
                    App::bif::log::_header(
                        'Subject', "[$path][$row->{status}] Re: $title"
                    )
                );
            }
            else {
                push( @data,
                    App::bif::log::_header( 'Subject', "[$path] Re: $title" ) );
            }

        }

        $row = pop @r;

        print $ctx->render_table( 'l  l', undef, \@data,
            4 * ( $row->{depth} - 1 ) )
          . "\n";

        print App::bif::log::_reformat( $row->{message}, $row->{depth} ), "\n";

    }

    $ctx->end_pager;
    return $ctx->ok('LogIssue');
}

1;
__END__

=head1 NAME

bif-log-issue - review the history of a issue

=head1 VERSION

0.1.0_24 (2014-06-13)

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

