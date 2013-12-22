package App::bif::new::project;
use strict;
use warnings;
use App::bif::Util;
use IO::Prompt::Tiny qw/prompt/;

our $VERSION = '0.1.0';

sub run {
    my $opts   = bif_init(shift);
    my $config = bif_conf($opts);
    my $db     = bif_dbw;

    DBIx::ThinSQL->import(qw/ qv /);

    $opts->{path} ||= prompt( 'Path:', '' )
      || bif_err( 'ProjectPathRequired', 'project path is required' );

    my $path = $opts->{path};

    bif_err( 'ProjectExists', 'project already exists: ' . $opts->{path} )
      if $db->path2project_id( $opts->{path} );

    if ( $opts->{path} =~ m/\// ) {
        my @parts = split( '/', $path );
        $opts->{path} = pop @parts;

        my $parent_path = join( '/', @parts );

        $opts->{parent_id} = $db->path2project_id($parent_path)
          || bif_err( 'ParentProjectNotFound',
            'parent project not found: ' . $parent_path );
    }

    my $where;
    if ( $opts->{status} ) {
        bif_err( 'InvalidStatus', 'unknown status: ' . $opts->{status} )
          unless $db->xarray(
            select => 'count(*)',
            from   => 'default_status',
            where  => {
                kind   => 'project',
                status => $opts->{status},
            }
          );
    }

    $opts->{title} ||= prompt( 'Title:', '' )
      || bif_err( 'ProjectNameRequired', 'project title is required' );

    $opts->{lang}   ||= 'en';
    $opts->{email}  ||= $config->{user}->{email};
    $opts->{author} ||= $config->{user}->{name};

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
                insert_into => 'func_new_project',
                values      => {
                    id        => $opts->{id},
                    update_id => $opts->{update_id},
                    parent_id => $opts->{parent_id},
                    name      => $opts->{path},
                    title     => $opts->{title},
                },
            );

            $db->xdo(
                insert_into => [
                    'func_new_project_status',
                    qw/project_id status status rank/
                ],
                select => [ qv( $opts->{id} ), qw/status status rank/, ],
                from   => 'default_status',
                where    => { kind => 'project' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into =>
                  [ 'project_updates', qw/update_id project_id status_id/, ],
                select => [
                    qv( $opts->{update_id} ),
                    qv( $opts->{id} ),
                    'project_status.id',
                ],
                from       => 'default_status',
                inner_join => 'project_status',
                on         => {
                    project_id              => $opts->{id},
                    'default_status.status' => \'project_status.status',
                },
                where => do {
                    if ( $opts->{status} ) {
                        {
                            'default_status.kind'   => 'project',
                            'default_status.status' => $opts->{status},
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
                insert_into =>
                  [ 'func_new_task_status', qw/project_id status rank def/ ],
                select => [ qv( $opts->{id} ), qw/status rank def/, ],
                from   => 'default_status',
                where    => { kind => 'task' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => [
                    'func_new_issue_status',
                    qw/project_id status status rank def/
                ],
                select => [ qv( $opts->{id} ), qw/status status rank def/, ],
                from   => 'default_status',
                where    => { kind => 'issue' },
                order_by => 'rank',
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

        }
    );

    printf( "Project created: %s\n", $path );
    return bif_ok( 'NewProject', $opts );
}

1;
__END__

=head1 NAME

bif-new-project - create a new project

=head1 VERSION

0.1.0 (yyyy-mm-dd)

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

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

