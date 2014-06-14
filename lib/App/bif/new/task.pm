package App::bif::new::task;
use strict;
use warnings;
use App::bif::Context;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_25';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    $ctx->{title} ||= prompt( 'Title:', '' )
      || return $ctx->err( 'TitleRequired', 'title is required' );

    if ( !$ctx->{path} ) {

        my ( $path, $count ) = $db->xarray(
            select   => [ "coalesce(p.path,'')", 'count(p.id)' ],
            from     => 'projects p',
            where    => 'p.local = 1',
            order_by => 'p.path',
        );

        if ( 0 == $count ) {
            return $ctx->err( 'NoProjectInRepo', 'task needs a project' );
        }
        elsif ( 1 == $count ) {
            $ctx->{path} = $path;
        }
        else {
            $ctx->{path} = prompt( 'Project:', $path )
              || return $ctx->err( 'ProjectRequired', 'project is required' );
        }
    }

    my $pinfo = $ctx->get_project( $ctx->{path} );

    if ( $ctx->{status} ) {
        my ( $status_ids, $invalid ) =
          $db->status_ids( $pinfo->{id}, 'task', $ctx->{status} );

        return $ctx->err( 'InvalidStatus',
            'unknown status: ' . join( ', ', @$invalid ) )
          if @$invalid;

        $ctx->{status_id} = $status_ids->[0];
    }
    else {
        ( $ctx->{status_id} ) = $db->xarray(
            select => 'id',
            from   => 'task_status',
            where  => { project_id => $pinfo->{id}, def => 1 },
        );
    }

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );

    $db->txn(
        sub {
            my $ruid = $db->nextval('updates');
            $ctx->{id}        = $db->nextval('topics');
            $ctx->{update_id} = $db->nextval('updates');

            $db->xdo(
                insert_into => 'updates',
                values      => {
                    id      => $ctx->{update_id},
                    email   => $ctx->{user}->{email},
                    author  => $ctx->{user}->{name},
                    message => $ctx->{message},
                },
            );

            $db->xdo(
                insert_into => 'func_new_task',
                values      => {
                    id        => $ctx->{id},
                    update_id => $ctx->{update_id},
                    status_id => $ctx->{status_id},
                    title     => $ctx->{title},
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $ctx->update_repo(
                {
                    id                => $ruid,
                    message           => "new task $ctx->{id} [$pinfo->{path}]",
                    related_update_id => $ctx->{update_id},
                }
            );
        }
    );

    printf( "Task created: %d\n", $ctx->{id} );
    return $ctx->ok('NewTask');
}

1;
__END__

=head1 NAME

bif-new-task - add a new task to a project

=head1 VERSION

0.1.0_25 (2014-06-14)

=head1 SYNOPSIS

    bif new task [PATH] [TITLE...] [OPTIONS...]

=head1 DESCRIPTION

Add a new task to a project.

=head1 ARGUMENTS

=over

=item PATH

The path of the project to which this task applies. Prompted for if not
provided.

=item TITLE

The summary of this task. Prompted for if not provided.

=back

=head1 OPTIONS

=over

=item --status, -s STATE

The initial status of the task. This must be a valid status for the
project as output by the L<bif-list-status>(1) command. A default is
used if not provided.

=item --message, -m MESSAGE

The body of the task. An editor will be invoked if not provided.

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

