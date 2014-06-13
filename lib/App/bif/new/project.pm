package App::bif::new::project;
use strict;
use warnings;
use App::bif::Context;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0_24';

sub run {
    my $ctx = App::bif::Context->new(shift);
    my $db  = $ctx->dbw;

    DBIx::ThinSQL->import(qw/ qv /);

    $ctx->{path} ||= prompt( 'Path:', '' )
      || return $ctx->err( 'ProjectPathRequired', 'project path is required' );

    my $path = $ctx->{path};

    return $ctx->err( 'ProjectExists',
        'project already exists: ' . $ctx->{path} )
      if eval { $ctx->get_project( $ctx->{path} ) };

    if ( $ctx->{path} =~ m/\// ) {
        my @parts = split( '/', $path );
        $ctx->{path} = pop @parts;

        my $parent_path = join( '/', @parts );

        my $parent_pinfo = eval { $ctx->get_project($parent_path) }
          || return $ctx->err( 'ParentProjectNotFound',
            'parent project not found: ' . $parent_path );
        $ctx->{parent_id} = $parent_pinfo->{id};
    }

    my $where;
    if ( $ctx->{status} ) {
        return $ctx->err( 'InvalidStatus', 'unknown status: ' . $ctx->{status} )
          unless $db->xarray(
            select => 'count(*)',
            from   => 'default_status',
            where  => {
                kind   => 'project',
                status => $ctx->{status},
            }
          );
    }

    $ctx->{title} ||= prompt( 'Title:', '' )
      || return $ctx->err( 'ProjectNameRequired', 'project title is required' );

    $ctx->{message} ||= $ctx->prompt_edit( opts => $ctx );
    $ctx->{lang} ||= 'en';

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
                insert_into => 'func_new_project',
                values      => {
                    update_id => $ctx->{update_id},
                    id        => $ctx->{id},
                    parent_id => $ctx->{parent_id},
                    name      => $ctx->{path},
                    title     => $ctx->{title},
                },
            );

            $db->xdo(
                update => 'projects',
                set    => {
                    local  => 1,
                    hub_id => $db->get_local_hub_id,
                },
                where => { id => $ctx->{id} },
            );

            $db->xdo(
                insert_into => [
                    'func_new_project_status',
                    qw/update_id project_id status status rank/
                ],
                select => [
                    qv( $ctx->{update_id} ),
                    qv( $ctx->{id} ),
                    qw/status status rank/,
                ],
                from     => 'default_status',
                where    => { kind => 'project' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into =>
                  [ 'project_deltas', qw/update_id project_id status_id/, ],
                select => [
                    qv( $ctx->{update_id} ),
                    qv( $ctx->{id} ),
                    'project_status.id',
                ],
                from       => 'default_status',
                inner_join => 'project_status',
                on         => {
                    project_id              => $ctx->{id},
                    'default_status.status' => \'project_status.status',
                },
                where => do {

                    if ( $ctx->{status} ) {
                        {
                            'default_status.kind'   => 'project',
                            'default_status.status' => $ctx->{status},
                        };
                    }
                    else {
                        {
                            'default_status.kind' => 'project',
                            'default_status.def'  => 1,
                        };
                    }
                },
            );

            $db->xdo(
                insert_into => [
                    'func_new_task_status',
                    qw/update_id project_id status rank def/
                ],
                select => [
                    qv( $ctx->{update_id} ),
                    qv( $ctx->{id} ),
                    qw/status rank def/,
                ],
                from     => 'default_status',
                where    => { kind => 'task' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_issue_status',
                    qw/update_id project_id status status rank def/
                ],
                select => [
                    qv( $ctx->{update_id} ),
                    qv( $ctx->{id} ),
                    qw/status status rank def/,
                ],
                from     => 'default_status',
                where    => { kind => 'issue' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            $ctx->update_repo(
                {
                    id         => $ruid,
                    message    => "new project $ctx->{id} [$ctx->{path}]",
                    project_id => $ctx->{id},
                    related_update_id => $ctx->{update_id},
                }
            );

        }
    );

    printf( "Project created: %s\n", $path );
    return $ctx->ok('NewProject');
}

1;
__END__

=head1 NAME

bif-new-project - create a new project

=head1 VERSION

0.1.0_24 (2014-06-13)

=head1 SYNOPSIS

    bif new project [PATH] [TITLE] [OPTIONS...]

=head1 DESCRIPTION

Create a new project according to the following items:

=over

=item PATH

An identifier for the project. Consists of the parent PATH (if any)
plus the the name of the project separated by a slash "/". Will be
prompted for if not provided.

=item TITLE

A short summary of what the project is about. Will be prompted for if
not provided.

=back


=head2 Options

=over

=item --message, -m MESSAGE

The project description.  An editor will be invoked to record a MESSAGE
if this option is not used.

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

