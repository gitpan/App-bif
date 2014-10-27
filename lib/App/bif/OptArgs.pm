package App::bif::OptArgs;

our $VERSION = '0.1.4';

package    # do a little hiding
  App::bif;
use strict;
use warnings;
use OptArgs;

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

opt user_repo => (
    isa     => 'Bool',
    alias   => 'c',
    comment => 'use the user repository',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# bif check
# ------------------------------------------------------------------------
subcmd(
    cmd     => 'check',
    hidden  => 1,
    comment => 'check all changeset UUIDs',
);

opt verbose => (
    isa     => 'Bool',
    alias   => 'v',
    comment => 'display YAML differences',
);

# ------------------------------------------------------------------------
# bif init
# ------------------------------------------------------------------------
subcmd(
    cmd     => 'init',
    comment => 'initialize a new repository',
);

arg name => (
    isa     => 'Str',
    comment => 'name of new hub',
);

arg location => (
    isa     => 'Str',
    comment => 'location of new remote hub',
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
    comment => 'create a new topic',
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
# new hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new hub/],
    comment => 'create a new hub',
);

arg name => (
    isa     => 'Str',
    comment => 'name of your organisation\'s hub',
);

arg locations => (
    isa     => 'ArrayRef',
    default => [],
    greedy  => 1,
    comment => 'hub locations',
);

opt default => (
    isa     => 'Bool',
    comment => 'mark hub as local/default',
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

opt self => (
    isa     => 'Bool',
    comment => 'Create a "self" identity',
);

opt shortname => (
    isa     => 'Str',
    alias   => 's',
    comment => 'identity initials or short name',
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

opt dup => (
    isa     => 'Str',
    alias   => 'd',
    comment => 'project path to duplicate',
);

opt issues => (
    isa     => 'Str',
    alias   => 'i',
    default => '',
    comment => 'fork, copy or move issues on --dup',
);

opt tasks => (
    isa     => 'Str',
    alias   => 't',
    default => '',
    comment => 'copy or move tasks on --dup',
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
# bif new repo
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/new repo/],
    comment => 'create an new empty repository',
);

arg directory => (
    isa      => 'Str',
    required => 1,
    comment  => 'location of repository',
);

opt config => (
    isa     => 'Bool',
    comment => 'Create a default repo config file',
);

# ------------------------------------------------------------------------
# bif list
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list/],
    comment => 'list topics in the repository',
);

arg items => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
);

# ------------------------------------------------------------------------
# bif list repo
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list actions/],
    comment => 'list actions in the current repository',
);

opt action => (
    isa     => 'Bool',
    alias   => 'a',
    comment => 'order actions by action ID instead of time'
);

# ------------------------------------------------------------------------
# bif list entities
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list entities/],
    comment => 'list entities (contacts)',
);

# ------------------------------------------------------------------------
# list hosts
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list hosts/],
    comment => 'list provider host locations',
);

# ------------------------------------------------------------------------
# list hubs
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list hubs/],
    comment => 'list hubs and their locations',
);

# ------------------------------------------------------------------------
# bif list identities
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list identities/],
    comment => 'list identities (contacts)',
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
# list plans
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list plans/],
    comment => 'list provider commercial offerings',
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
# list providers
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/list providers/],
    comment => 'list registered providers',
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
# bif show
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show/],
    comment => "display a topic's current status",
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
    alias   => 'U',
    comment => 'treat ID as a UUID',
);

opt full => (
    isa     => 'Bool',
    comment => 'display a more verbose current status',
    alias   => 'f',
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
# bif show issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show issue/],
    comment => 'summarize the current status of a issue',
);

arg id => (
    isa      => 'Int',
    comment  => 'issue ID',
    required => 1,
);

# ------------------------------------------------------------------------
# show plan
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show plan/],
    comment => 'show a provider plan',
);

arg id => (
    isa      => 'Str',
    required => 1,
    comment  => 'ID of provider plan',
);

# ------------------------------------------------------------------------
# bif show project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show project/],
    comment => 'display current project status',
);

arg path => (
    isa      => 'Str',
    comment  => 'a project PATH',
    required => 1,
);

# ------------------------------------------------------------------------
# bif show table
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show table/],
    comment => 'summarize the current status of a table',
);

arg name => (
    isa      => 'Str',
    required => 1,
    comment  => 'table name',
);

# ------------------------------------------------------------------------
# bif show task
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show task/],
    comment => 'summarize the current status of a task',
);

arg id => (
    isa      => 'Int',
    comment  => 'task ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif show change
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/show change/],
    comment => 'show an update as YAML',
);

arg uid => (
    isa      => 'Str',
    required => 1,
    comment  => 'the change cID',
);

# ------------------------------------------------------------------------
# bif log
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log/],
    comment => 'view comments and status history',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID or project PATH',
    },
);

opt uuid => (
    isa     => 'Bool',
    alias   => 'U',
    comment => 'treat arguments as if they are a UUIDs',
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
# bif log project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log project/],
    comment => 'review history of a project',
);

arg path => (
    isa      => 'Str',
    comment  => 'project PATH or ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif log task
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/log task/],
    comment => 'review history of a task',
);

arg id => (
    isa      => 'Str',
    comment  => 'task ID',
    required => 1,
);

# ------------------------------------------------------------------------
# bif update
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update/],
    comment => 'comment on or modify a topic',
);

arg id => (
    isa      => 'SubCmd',
    required => 1,
    comment  => 'topic ID or project PATH',
    fallback => {
        name    => 'id',
        isa     => 'Str',
        comment => 'topic ID or project PATH',
    },
);

opt uuid => (
    isa     => 'Bool',
    alias   => 'U',
    comment => 'treat ID as a UUID',
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

opt reply => (
    isa     => 'Str',
    comment => 'reply to a change cID',
    alias   => 'r',
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

opt shortname => (
    isa     => 'Str',
    alias   => 's',
    comment => 'identity initials or short name',
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
# bif update hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update hub/],
    comment => 'update a hub',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'hub ID',
);

# ------------------------------------------------------------------------
# bif update issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update issue/],
    comment => 'update an issue',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'issue ID',
);

arg status => (
    isa     => 'Str',
    comment => 'topic status',
);

opt title => (
    isa     => 'Str',
    alias   => 't',
    comment => 'Title',
);

# ------------------------------------------------------------------------
# bif update project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update project/],
    comment => 'update an project',
);

arg path => (
    isa      => 'Str',
    required => 1,
    comment  => 'project path',
);

arg status => (
    isa     => 'Str',
    comment => 'topic status',
);

opt title => (
    isa     => 'Str',
    alias   => 't',
    comment => 'Title',
);

# ------------------------------------------------------------------------
# bif update task
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/update task/],
    comment => 'update an task',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'task ID',
);

arg status => (
    isa     => 'Str',
    comment => 'topic status',
);

opt title => (
    isa     => 'Str',
    alias   => 't',
    comment => 'Title',
);

# ------------------------------------------------------------------------
# bif drop
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop/],
    comment => 'remove an item from the database',
    hidden  => 1,
);

arg item => (
    isa      => 'SubCmd',
    required => 1,
    comment  => 'topic ID or project PATH',
);

opt force => (
    isa     => 'Bool',
    alias   => 'f',
    comment => 'Do not ask for confirmation',
);

# ------------------------------------------------------------------------
# bif drop hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop hub/],
    comment => 'remove a hub',
);

arg name => (
    isa      => 'Str',
    required => 1,
    comment  => 'hub name (TODO: or ID)',
);

# ------------------------------------------------------------------------
# bif drop issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop issue/],
    comment => 'remove an issue',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'issue ID',
);

# ------------------------------------------------------------------------
# bif drop project
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop project/],
    comment => 'remove a project',
);

arg path => (
    isa      => 'Str',
    required => 1,
    comment  => 'project PATH or ID',
);

# ------------------------------------------------------------------------
# bif drop task
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop task/],
    comment => 'remove a task',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'task ID',
);

# ------------------------------------------------------------------------
# bif drop change
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/drop change/],
    comment => 'remove a change',
);

arg uid => (
    isa      => 'Int',
    required => 1,
    comment  => 'change cID',
);

# ------------------------------------------------------------------------
# bif pull
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/pull/],
    comment => 'import topics from elsewhere',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
);

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    hidden  => 1,
    comment => 'turn on bifsync debugging',
);

# ------------------------------------------------------------------------
# bif pull identity
# ------------------------------------------------------------------------

subcmd(
    cmd     => [qw/pull identity/],
    comment => 'import an identity from a repository',
);

arg location => (
    isa      => 'Str',
    required => 1,
    comment  => 'location of identity repository',
);

# For the moment just handle self identities.
#arg identity => (
#    isa      => 'Str',
#    comment  => 'location of identity repository',
#);

opt self => (
    isa     => 'Bool',
    comment => 'register identity as "myself" after import',
);

# ------------------------------------------------------------------------
# pull hub
# ------------------------------------------------------------------------

subcmd(
    cmd     => [qw/pull hub/],
    comment => 'import project list from a hub repository',
);

arg location => (
    isa      => 'Str',
    required => 1,
    comment  => 'location of a remote repository',
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

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# pull provider
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/pull provider/],
    comment => 'import plans from a provider',
);

arg location => (
    isa      => 'Str',
    required => 1,
    comment  => 'management location of provider',
);

# ------------------------------------------------------------------------
# bif push
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/push/],
    comment => 'export topics to somewhere else',
);

arg item => (
    isa      => 'SubCmd',
    comment  => '',
    required => 1,
);

opt message => (
    isa     => 'Str',
    comment => 'optional comment for the associated change',
    alias   => 'm',
);

# ------------------------------------------------------------------------
# push hub
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/push hub/],
    comment => 'export a hub to a provider host',
);

arg name => (
    isa      => 'Str',
    required => 1,
    comment  => 'name of your organisation\'s hub',
);

arg hosts => (
    isa      => 'ArrayRef',
    required => 1,
    greedy   => 1,
    comment  => 'provider host address(es)',
);

# ------------------------------------------------------------------------
# bif push issue
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/push issue/],
    comment => 'push an issue to another project',
);

arg id => (
    isa      => 'Int',
    required => 1,
    comment  => 'issue ID',
);

arg path => (
    isa      => 'ArrayRef',
    required => 1,
    greedy   => 1,
    comment  => 'path(s) of the destination project(s)',
);

opt err_on_exists => (
    isa     => 'Bool',
    comment => 'raise an error when issue exists at destination',
    hidden  => 1,
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

opt debug_bifsync => (
    isa     => 'Bool',
    alias   => 'E',
    comment => 'turn on bifsync debugging',
    hidden  => 1,
);

# ------------------------------------------------------------------------
# signup
# ------------------------------------------------------------------------
subcmd(
    cmd     => [qw/signup/],
    comment => 'sign up with a hub provider',
    hidden  => 1,
);

arg name => (
    isa      => 'Str',
    required => 1,
    comment  => 'hub name',
);

arg plan => (
    isa      => 'Str',
    required => 1,
    comment  => 'provider plan name',
);

opt debug_bs => (
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
    comment => 'exchange changes with a hub',
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
    comment => 'message for multiple test script changes / second ',
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

opt write => (
    isa     => 'Bool',
    comment => 'run with a writeable database (default is read-only)',
    alias   => 'w',
);

1;
__END__


=head1 NAME

=for bif-doc #perl

App::bif::OptArgs - bif command argument & option definitions

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

  use App::bif::OptArgs;
  use OptArgs qw/class_optargs/;
  my ($class, $opts) = class_optargs('App::bif');

=head1 DESCRIPTION

This package holds the L<OptArgs> definitions for L<bif>.

=head1 SEE ALSO

L<bif>, L<OptArgs>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

