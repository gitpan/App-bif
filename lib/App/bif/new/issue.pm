package App::bif::new::issue;
use strict;
use warnings;
use App::bif::Util;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0';

sub run {
    my $opts   = bif_init(shift);
    my $config = bif_conf;
    my $db     = bif_dbw;

    $opts->{title} ||= prompt( 'Title:', '' )
      || bif_err( 'TitleRequired', 'title is required' );

    $opts->{path} ||= do {

        # just grab the first one
        my ($project) = $db->xarray(
            select   => "coalesce(path,'')",
            from     => 'projects',
            order_by => 'path',
            limit    => 1,
        );
        prompt( 'Project:', $project );
      }
      || bif_err( 'ProjectRequired', 'project is required' );

    bif_err( 'ProjectNotFound', 'project not found: ' . $opts->{path} )
      unless $opts->{project_id} = $db->path2project_id( $opts->{path} );

    if ( $opts->{status} ) {
        my ( $status_ids, $invalid ) =
          $db->status_ids( $opts->{project_id}, 'issue', $opts->{status} );

        bif_err( 'InvalidStatus', 'unknown status: ' . join( ', ', @$invalid ) )
          if @$invalid;

        $opts->{status_id} = $status_ids->[0];
    }
    else {
        ( $opts->{status_id} ) = $db->xarray(
            select => 'id',
            from   => 'issue_status',
            where  => { project_id => $opts->{project_id}, def => 1 },
        );
    }

    $opts->{author}  ||= $config->{user}->{name};
    $opts->{email}   ||= $config->{user}->{email};
    $opts->{message} ||= prompt_edit( opts => $opts );
    $opts->{id}        = $db->nextval('topics');
    $opts->{update_id} = $db->nextval('updates');

    $db->txn(
        sub {
            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id      => $opts->{update_id},
                    email   => $opts->{email},
                    author  => $opts->{author},
                    message => $opts->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_new_issue',
                values      => {
                    id        => $opts->{id},
                    update_id => $opts->{update_id},
                    status_id => $opts->{status_id},
                    title     => $opts->{title},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    printf( "Issue created: %d\n", $opts->{id} );
    return bif_ok( 'NewIssue', $opts );
}

1;
__END__

=head1 NAME

bif-new-issue - add a new issue to a project

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    bif new issue [PATH] [TITLE...] [OPTIONS...]

=head1 DESCRIPTION

Add a new issue to a project.

=head1 ARGUMENTS

=over

=item PATH

The path of the project to which this issue applies. Prompted for if
not provided.

=item TITLE

The summary of this issue. Prompted for if not provided.

=back

=head1 OPTIONS

=over

=item --status, -s STATE

The initial status of the issue. This must be a valid status for the
project as output by the L<bif-list-status>(1) command. A default is
used if not provided.

=item --message, -m MESSAGE

The body of the issue. An editor will be invoked if not provided.

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

