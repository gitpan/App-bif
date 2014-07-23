package App::bif;
use strict;
use warnings;
use OptArgs ':all';

our $VERSION = '0.1.0_26';

$OptArgs::COLOUR = 1;
$OptArgs::SORT   = 1;

arg command => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
    fallback => {
        name    => 'alias',
        isa     => 'ArrayRef',
        comment => 'run a command alias',
        greedy  => 1,
        hidden  => 1,
    },
);

opt help => (
    isa     => 'Bool',
    alias   => 'h',
    ishelp  => 1,
    comment => 'print a full usage message and exit',
);

opt debug => (
    isa     => 'Bool',
    alias   => 'D',
    comment => 'turn on debugging',
    hidden  => 1,
);

opt no_pager => (
    isa     => 'Bool',
    comment => 'do not page output',
    hidden  => 1,
);

opt no_color => (
    isa     => 'Bool',
    comment => 'do not colorize output',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif init
# ------------------------------------------------------------------------
subcmd(
    cmd     => 'init',
    comment => 'initialize a new repository in .bif',
);

arg directory => (
    isa     => 'Str',
    comment => 'parent location of .bif directory',
);

opt bare => (
    isa     => 'Bool',
    comment => 'use DIRECTORY directly (no .bif)',
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif register
# ------------------------------------------------------------------------

subcmd(
    cmd     => [qw/register/],
    comment => 'register with a bif hub repository',
);

arg location => (
    isa      => 'Str',
    required => 1,
    comment  => 'location of a remote repository',
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif new
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new/],
    comment => 'create a new project, task or issue',
);

arg item => (
    isa      => 'SubCmd',
    required => 1,
    comment  => '',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
    hidden  => 1,
);

opt email => (
    isa     => 'Str',
    comment => 'Email',
    hidden  => 1,
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
    hidden  => 1,
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
    hidden  => 1,
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'State',
);

opt message => (
    isa     => 'Str',
    alias   => 'm',
    comment => 'Comment',
);

# ------------------------------------------------------------------------
# bif new identity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new identity/],
    comment => 'create a new identity',
);

arg name => (
    isa     => 'Str',
    comment => 'The name of the identity',
);

arg method => (
    isa     => 'Str',
    comment => 'The contact type (email, phone, etc)',
);

arg value => (
    isa     => 'Str',
    comment => 'The contact value',
);

# ------------------------------------------------------------------------
# bif new entity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new entity/],
    comment => 'create a new entity',
);

arg name => (
    isa     => 'Str',
    comment => 'The name of the entity',
);

arg method => (
    isa     => 'Str',
    comment => 'The contact type (email, phone, etc)',
);

arg value => (
    isa     => 'Str',
    comment => 'The contact value',
);

# ------------------------------------------------------------------------
# bif new project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new project/],
    comment => 'create a new project',
);

arg path => (
    isa     => 'Str',
    comment => 'The path of the project',
);

arg title => (
    isa     => 'Str',
    comment => 'A short description of the project',
    greedy  => 1,
);

opt phase => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'Initial project phase (use instead of --status)',
);

# ------------------------------------------------------------------------
# bif new task
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new task/],
    comment => 'define an item of work',
);

arg title => (
    isa     => 'Str',
    comment => 'summary of the task description',
    greedy  => 1,
);

opt path => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'path of the containing project',
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'Initial status for the task',
);

# ------------------------------------------------------------------------
# bif new issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new issue/],
    comment => 'define a problem to be solved',
);

arg title => (
    isa     => 'Str',
    comment => 'summary of the issue description',
    greedy  => 1,
);

opt path => (
    isa     => 'Str',
    alias   => 'p',
    comment => 'path of the containing project',
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'Initial status for the task',
);

# ------------------------------------------------------------------------
# bif list
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list/],
    comment => 'list various things in the database',
);

arg items => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
);

# ------------------------------------------------------------------------
# bif list identities
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list identities/],
    comment => 'list identities (contacts)',
);

# ------------------------------------------------------------------------
# bif list entities
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list entities/],
    comment => 'list entities (contacts)',
);

# ------------------------------------------------------------------------
# bif list tasks
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list tasks/],
    comment => 'list tasks grouped by project',
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'limit tasks to a specific status',
);

opt project_status => (
    isa     => 'Str',
    alias   => 'P',
    comment => 'limit projects by a particular project status',
);

# ------------------------------------------------------------------------
# bif list issues
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list issues/],
    comment => 'list issues grouped by project',
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'limit issues to a specific status',
);

opt project_status => (
    isa     => 'Str',
    alias   => 'P',
    comment => 'limit projects by a particular project status',
);

# ------------------------------------------------------------------------
# bif list project-topic
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list topics/],
    comment => 'list tasks and issues grouped by project',
);

opt status => (
    isa     => 'Str',
    alias   => 's',
    comment => 'limit topics to a specific status',
);

opt project_status => (
    isa     => 'Str',
    alias   => 'P',
    comment => 'limit projects by a particular project status',
);

# ------------------------------------------------------------------------
# bif list projects
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list projects/],
    comment => 'list projects with topic counts and progress',
);

arg status => (
    isa     => 'ArrayRef',
    greedy  => 1,
    comment => 'limit the list by status type(s)',
);

opt hub => (
    isa     => 'Str',
    alias   => 'H',
    comment => 'Limit the list to projects located at HUB',
);

opt local => (
    isa     => 'Bool',
    alias   => 'l',
    comment => 'limit the list to projects that synchronise.',
);

# ------------------------------------------------------------------------
# bif list project-status
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list project-status/],
    comment => 'list valid status for projects',
);

arg path => (
    isa      => 'Str',
    comment  => 'the path of a project',
    required => 1,
);

# ------------------------------------------------------------------------
# bif list issue-status
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list task-status/],
    comment => 'list valid status for tasks',
);

arg path => (
    isa      => 'Str',
    comment  => 'the path of a project',
    required => 1,
);

# ------------------------------------------------------------------------
# bif list task-status
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list issue-status/],
    comment => 'list valid status for issues',
);

arg path => (
    isa      => 'Str',
    comment  => 'the path of a project',
    required => 1,
);

# ------------------------------------------------------------------------
# bif list hubs
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list hubs/],
    comment => 'list hubs and their locations',
);

# ------------------------------------------------------------------------
# bif show
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show/],
    comment => 'summarize the current status of a topic',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID or project PATH',
    },
);

opt uuid => (
    isa     => 'Bool',
    alias   => 'u',
    comment => 'treat ID as a UUID',
);

opt full => (
    isa     => 'Bool',
    comment => 'display a more verbose current status',
    alias   => 'f',
);

# ------------------------------------------------------------------------
# bif show identity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show identity/],
    comment => 'display full identity characteristics',
);

arg id => (
    isa      => 'Int',
    comment  => 'identity ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif show entity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show entity/],
    comment => 'display full entity characteristics',
);

arg id => (
    isa      => 'Int',
    comment  => 'entity ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif show hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show hub/],
    comment => 'summarize the current status of a hub',
);

arg name => (
    isa      => 'Str',
    comment  => 'hub name',
    required => 1,
);

# ------------------------------------------------------------------------
# bif show project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show project/],
    comment => 'display current project status',
);

arg id => (
    isa      => 'Str',
    comment  => 'topic ID or project PATH',
    required => 1,
);

arg hub => (
    isa     => 'Str',
    comment => 'hub ALIAS or LOCATION',
);

# ------------------------------------------------------------------------
# bif log
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log/],
    comment => 'review change history and comments',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID or project PATH',
        greedy  => 1,
    },
);

opt uuid => (
    isa     => 'Bool',
    alias   => 'u',
    comment => 'treat arguments as if they are a UUIDs',
);

opt filter => (
    isa     => 'ArrayRef',
    comment => 'only show entries of a particular type',
    alias   => 'f',
    default => [],
);

# ------------------------------------------------------------------------
# bif log identity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log identity/],
    comment => 'review history of an identity',
);

arg id => (
    isa      => 'Str',
    comment  => 'identity ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif log entity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log entity/],
    comment => 'review history of an entity',
);

arg id => (
    isa      => 'Str',
    comment  => 'entity ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif log hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log hub/],
    comment => 'review history of a hub',
);

arg name => (
    isa      => 'Str',
    comment  => 'hub name',
    required => 1,
);

# ------------------------------------------------------------------------
# bif log issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log issue/],
    comment => 'review history of an issue',
);

arg id => (
    isa      => 'Str',
    comment  => 'issue ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif update
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update/],
    comment => 'update or comment a topic',
);

arg id => (
    isa      => 'SubCmd',
    required => 1,
    comment  => 'topic ID or project PATH',
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID or project PATH',
        greedy  => 1,
    },
);

arg status => (
    isa     => 'Str',
    comment => 'topic status (or project phase)',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
    hidden  => 1,
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
    hidden  => 1,
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
    hidden  => 1,
);

opt title => (
    isa     => 'Str',
    alias   => 't',
    comment => 'Title',
);

opt message => (
    isa     => 'Str',
    comment => 'Comment',
    alias   => 'm',
);

# ------------------------------------------------------------------------
# bif update identity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update identity/],
    comment => 'update an identity',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'identity ID',
);

# ------------------------------------------------------------------------
# bif update entity
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update entity/],
    comment => 'update an entity',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'entity ID',
);

# ------------------------------------------------------------------------
# bif reply
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/reply/],
    comment => 'reply to a previous update or comment',
);

arg 'id.uid' => (
    isa      => 'Str',
    required => 1,
    comment  => 'topic and update ID of previous comment',
);

opt author => (
    isa     => 'Str',
    comment => 'Author',
    hidden  => 1,
);

opt lang => (
    isa     => 'Str',
    comment => 'Lang',
    hidden  => 1,
);

opt locale => (
    isa     => 'Str',
    comment => 'Locale',
    hidden  => 1,
);

opt message => (
    isa     => 'Str',
    comment => 'Comment',
    alias   => 'm',
);

# ------------------------------------------------------------------------
# bif drop
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop/],
    comment => 'remove a topic from the database',
    hidden  => 1,
);

arg id => (
    isa      => 'Str',
    comment  => 'topic ID or project PATH',
    required => 1,
);

opt force => (
    isa     => 'Bool',
    alias   => 'f',
    comment => 'Do not ask for confirmation',
);

# ------------------------------------------------------------------------
# bif pull
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/pull/],
    comment => 'import a topic from elsewhere',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
);

# ------------------------------------------------------------------------
# bif pull project
# ------------------------------------------------------------------------

subcmd(
    cmd     => [qw/pull project/],
    comment => 'import projects from a hub',
);

arg path => (
    isa      => 'ArrayRef',
    greedy   => 1,
    required => 1,
    comment  => 'path(s) of the project(s) to be imported',
);

arg hub => (
    isa      => 'Str',
    required => 1,
    comment  => 'source hub address or alias',
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif push
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/push/],
    comment => 'push a topic to another project',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID to be pushed',
    },
);

# TODO Fix OptArgs so usage is correct with arg after subcmd
arg path => (
    isa      => 'Str',
    required => 1,
    comment  => 'destination project path',
);

arg hub => (
    isa     => 'Str',
    comment => 'hub that hosts the destination project',
);

opt message => (
    isa     => 'Str',
    comment => 'reason for this push to the project',
    alias   => 'm',
);

# ------------------------------------------------------------------------
# bif push project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/push project/],
    comment => 'export a project to a hub',
);

arg path => (
    isa      => 'ArrayRef',
    required => 1,
    greedy   => 1,
    comment  => 'path(s) of the project(s) to be exported',
);

arg hub => (
    isa      => 'Str',
    required => 1,
    comment  => 'destination hub address or alias',
);

opt message => (
    isa     => 'Str',
    alias   => 'm',
    default => '',
    comment => 'optional comment for the associated update',
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif sync
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/sync/],
    comment => 'exchange updates with a hub',
);

opt path => (
    isa     => 'ArrayRef',
    alias   => 'p',
    comment => 'limit sync to a particular project',
);

opt hub => (
    isa     => 'ArrayRef',
    alias   => 'H',
    comment => 'limit sync to a particular hub',
);

opt message => (
    isa     => 'Str',
    alias   => 'm',
    default => '',
    hidden  => 1,
    comment => 'message for multiple test script updates / second ',
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif upgrade
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/upgrade/],
    comment => 'upgrade a repository',
    hidden  => 1,
);

arg directory => (
    isa     => 'Str',
    comment => 'location if this is a hub upgrade',
);

# ------------------------------------------------------------------------
# bif sql
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/sql/],
    comment => 'run an SQL command against the database',
    hidden  => 1,
);

arg statement => (
    isa     => 'Str',
    comment => 'SQL statement text',
    greedy  => 1,
);

opt noprint => (
    isa     => 'Bool',
    comment => 'do not print output but return a data structure',
    alias   => 'n',
);

opt user => (
    isa     => 'Bool',
    comment => 'run query against the user identity database',
    alias   => 'u',
);

opt write => (
    isa     => 'Bool',
    comment => 'run with a writeable database (default is read-only)',
    alias   => 'w',
);

# Run user defined aliases
sub run {
    my $opts = shift;
    my @cmd  = @{ delete $opts->{alias} };

    require App::bif::Context;
    my $ctx = App::bif::Context->new($opts);

    my $alias = shift @cmd;

    my $str = $ctx->{'user.alias'}->{$alias}
      or die usage(qq{unknown COMMAND or ALIAS "$alias"});

    # Make sure these options are correctly passed through (or not)
    $opts->{debug}    = undef if exists $opts->{debug};
    $opts->{no_pager} = undef if exists $opts->{no_pager};
    $opts->{no_color} = undef if exists $opts->{no_color};

    unshift( @cmd, split( ' ', $str ) );

    require Log::Any;
    Log::Any->get_logger( category => __PACKAGE__ )
      ->debug("alias: $alias => @cmd");
    return dispatch( 'run', 'App::bif', $opts, @cmd );
}

1;
__END__


=head1 NAME

App::bif - OptArgs dispatch module for bif.

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

  use OptArgs qw/dispatch/;
  dispatch(qw/run App::bif/);

=head1 DESCRIPTION

See L<bif>(1) for details.

=head1 SEE ALSO

L<OptArgs>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

