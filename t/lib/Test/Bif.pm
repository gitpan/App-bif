package Test::Bif;
use strict;
use warnings;
use Exporter::Tidy default => [
    qw/
      run_in_tempdir
      bif
      debug_on
      debug_off
      new_test_update
      new_test_hub
      new_test_project
      new_test_project_status
      new_test_task_status
      new_test_issue_status
      new_test_task
      new_test_issue
      /
];
use File::chdir;
use Log::Any '$log';
use Log::Any::Adapter;
use Log::Any::Adapter::Diag;
use OptArgs qw/dispatch/;
use Path::Tiny;
use Time::Piece;
require Test::More;

our $VERBOSE;
our $SRC_DIR = path(__FILE__)->parent(4)->absolute;

$main::BIF_SHARE_DIR = $SRC_DIR->child('share');
$main::BIF_DB_NOSYNC = 1;

# Ensure that our test bifsync is found by tests
$ENV{PATH} = $SRC_DIR->child('t') . ':' . $ENV{PATH};

sub run_in_tempdir (&) {
    my $sub = shift;
    my $tmp = Path::Tiny->tempdir( CLEANUP => 1 );

    {
        $log->debug("cd $tmp");
        local $CWD = $tmp;
        local $ENV{HOME} = $tmp;    # Don't use the testers HOME
        $sub->();
    }

    return;
}

sub bif {

    my @bif = (qw/ run App::bif --no-pager /);

    my $stdout;
    my $junk;

    if ( !$VERBOSE ) {
        open( $stdout, '>&', 'STDOUT' )     or die "open: $!";
        open( STDOUT,  '>',  'stdout.txt' ) or die "open: $!";
    }

    Test::More::diag("@bif @_") if $VERBOSE;
    my $result = eval { dispatch( @bif, @_ ) };
    my $err = $@;

    if ( !$VERBOSE ) {
        open( STDOUT, '>&', $stdout );
        close $stdout;
        unlink 'stdout.txt';
    }

    die $err if $err;

    return $result;
}

my $DEBUG;

sub debug_on {
    return if $DEBUG;
    $DEBUG = Log::Any::Adapter->set('Diag');
}

sub debug_off {
    return unless $DEBUG;
    Log::Any::Adapter->remove($DEBUG);
    $DEBUG = undef;
}

my $update = 0;

sub new_test_update {
    my $db  = shift;
    my $ref = {
        id      => $db->nextval('updates'),
        mtime   => int( rand(time) ),
        mtimetz => int( Time::Piece->new->tzoffset ),
        author  => 'author' . $update++,
        email   => 'email' . $update++,
    };
    $db->xdo(
        insert_into => 'updates',
        values      => $ref,
    );
    return $ref;
}

my $location = 0;

sub new_test_hub {
    my $dbw    = shift;
    my $local  = shift;
    my $update = new_test_update($dbw);

    my $id  = $dbw->nextval('topics');
    my $lid = $dbw->nextval('topics');

    my $ref = {
        id        => $id,
        update_id => $update->{id},
        local     => $local,
        name      => 'location' . $location++,
    };

    $dbw->xdo(
        insert_into => 'func_new_hub',
        values      => $ref,
    );

    $dbw->xdo(
        insert_into => 'func_new_hub_repo',
        values      => {
            update_id => $update->{id},
            hub_id    => $id,
            id        => $lid,
            location  => 'location' . $location++,
        },
    );

    $dbw->xdo(
        insert_into => 'hub_deltas',
        values      => {
            update_id => $update->{id},
            hub_id    => $id,
        },
    );

    $dbw->xdo(
        update => 'hubs',
        set    => { default_repo_id => $lid, },
        where  => { id => $id },
    );

    $dbw->xdo(
        insert_into => 'func_merge_updates',
        values      => { merge => 1 },
    );

    return $ref;
}

my $project = 0;

sub new_test_project {
    my $db        = shift;
    my $update_id = shift || $db->currval('updates');
    my $id        = $db->nextval('topics');

    $project++;

    my $ref = {
        update_id => $update_id,
        id        => $id,
        name      => 'todo' . $project,
        title     => 'title' . $project,
    };

    $db->xdo(
        insert_into => 'func_new_project',
        values      => $ref,
    );

    $db->xdo(
        update => 'projects',
        set    => 'local = 1',
        where  => { id => $id },
    );

    return $ref;
}

my $project_status = 0;

sub new_test_project_status {
    my $db        = shift;
    my $project   = shift;
    my $update_id = shift || $db->currval('updates');

    $project_status++;

    my $ref = {
        update_id  => $update_id,
        id         => $db->nextval('topics'),
        status     => 'status' . $project_status,
        rank       => $project_status,
        project_id => $project->{id},
    };

    $db->xdo(
        insert_into => 'func_new_project_status',
        values      => $ref,
    );

    return $ref;
}

my $task_status = 0;

sub new_test_task_status {
    my $db        = shift;
    my $project   = shift;
    my $update_id = shift || $db->currval('updates');

    $task_status++;

    my $ref = {
        update_id  => $update_id,
        id         => $db->nextval('topics'),
        status     => 'status' . $task_status,
        rank       => $task_status,
        project_id => $project->{id},
        def        => $task_status == 1,
    };

    $db->xdo(
        insert_into => 'func_new_task_status',
        values      => $ref,
    );

    return $ref;
}

my $issue_status = 0;

sub new_test_issue_status {
    my $db        = shift;
    my $project   = shift;
    my $update_id = shift || $db->currval('updates');

    $issue_status++;

    my $ref = {
        update_id  => $update_id,
        id         => $db->nextval('topics'),
        status     => 'status' . $issue_status,
        rank       => $issue_status,
        project_id => $project->{id},
        def        => $issue_status == 1,
    };

    $db->xdo(
        insert_into => 'func_new_issue_status',
        values      => $ref,
    );

    return $ref;
}

my $task = 0;

sub new_test_task {
    $task++;
    my $db        = shift;
    my $status    = shift;
    my $update_id = shift || $db->currval('updates');

    $task++;

    my $ref = {
        update_id => $update_id,
        id        => $db->nextval('topics'),
        title     => 'title' . $task,
        status_id => $status->{id},
    };

    $db->xdo(
        insert_into => 'func_new_task',
        values      => $ref,
    );

    return $ref;
}

my $issue = 0;

sub new_test_issue {
    $issue++;
    my $db        = shift;
    my $status    = shift;
    my $update_id = shift || $db->currval('updates');

    $issue++;

    my $ref = {
        update_id => $update_id,
        id        => $db->nextval('topics'),
        title     => 'title' . $issue,
        status_id => $status->{id},
    };

    $db->xdo(
        insert_into => 'func_new_issue',
        values      => $ref,
    );

    return $ref;
}

1;
__END__
