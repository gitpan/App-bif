package Test::Bif;
use strict;
use warnings;
use App::bif::OptArgs;
use Exporter::Tidy default => [
    qw/
      run_in_tempdir
      bif
      bif2
      bifsync
      debug_on
      debug_off
      new_test_change
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
use OptArgs qw/class_optargs/;
use Path::Tiny;
use Time::Piece;
require Test::More;

our $VERBOSE;
our $SRC_DIR = path(__FILE__)->parent(4)->absolute;

$main::BIF_SHARE_DIR = $SRC_DIR->child('share');
$main::BIF_DB_NOSYNC = 1;

# Ensure that our test bifsync is found by tests
die "Cannot find test bifsync" unless -e $SRC_DIR->child(qw/tbin bifsync/);
$ENV{PATH} = $SRC_DIR->child('tbin') . ':' . $ENV{PATH};

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
    my @bif = ( qw/ --no-pager /, @_ );

    my $stdout;
    my $junk;

    if ( !$VERBOSE ) {
        open( $stdout, '>&', 'STDOUT' )     or die "open: $!";
        open( STDOUT,  '>',  'stdout.txt' ) or die "open: $!";
    }

    Test::More::diag("@bif") if $VERBOSE;
    my $result = eval {
        my ( $class, $opts ) = class_optargs( 'App::bif', @bif );
        $class->new( opts => $opts )->run;
    };
    my $err = $@;

    if ( !$VERBOSE ) {
        open( STDOUT, '>&', $stdout );
        close $stdout;
        unlink 'stdout.txt';
    }

    die $err if $err;

    return $result;
}

sub bif2 {
    mkdir 'home2' unless -d 'home2';
    local $CWD = 'home2';
    local $ENV{HOME} = Path::Tiny->cwd;
    return bif(@_);
}

sub bifsync {
    my $stdout;
    my $junk;

    if ( !$VERBOSE ) {
        open( $stdout, '>&', 'STDOUT' )     or die "open: $!";
        open( STDOUT,  '>',  'stdout.txt' ) or die "open: $!";
    }

    Test::More::diag("@_") if $VERBOSE;
    my $result = eval {
        my ( $class, $opts ) = class_optargs( 'App::bifsync', @_ );
        $class->new( opts => $opts )->run;
    };
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

my $change = 0;

sub new_test_change {
    my $db  = shift;
    my $ref = {
        id          => $db->nextval('changes'),
        mtime       => int( rand(time) ),
        mtimetz     => int( Time::Piece->new->tzoffset ),
        author      => 'author' . $change++,
        email       => 'email' . $change++,
        identity_id => $db->xval(
            select => 'b.identity_id',
            from   => 'bifkv b',
            where  => { 'b.key' => 'self' },
        ),
    };
    $db->xdo(
        insert_into => 'changes',
        values      => $ref,
    );

    return $ref;
}

my $location = 0;

sub new_test_hub {
    my $db     = shift;
    my $local  = shift;
    my $change = new_test_change($db);

    my $id  = $db->nextval('topics');
    my $lid = $db->nextval('topics');

    my $ref = {
        id        => $id,
        change_id => $change->{id},
        local     => $local,
        name      => 'location' . $location++,
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change->{id},
            id        => $id,
            kind      => 'hub',
        },
    );

    $db->xdo(
        insert_into => 'func_new_hub',
        values      => $ref,
    );

    debug_on;
    $db->xdo(
        insert_into => 'func_new_hub_repo',
        values      => {
            change_id => $change->{id},
            hub_id    => $id,
            id        => $lid,
            location  => 'location' . $location++,
        },
    );

    $db->xdo(
        insert_into => 'hub_deltas',
        values      => {
            change_id => $change->{id},
            hub_id    => $id,
        },
    );

    $db->xdo(
        update => 'hubs',
        set    => { default_repo_id => $lid, },
        where  => { id => $id },
    );

    $db->xdo(
        insert_into => 'func_merge_changes',
        values      => { merge => 1 },
    );

    return $ref;
}

my $project = 0;

sub new_test_project {
    my $db        = shift;
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');

    $project++;

    my $ref = {
        change_id => $change_id,
        id        => $id,
        name      => 'todo' . $project,
        title     => 'title' . $project,
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $id,
            kind      => 'project',
        },
    );

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
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');

    $project_status++;

    my $ref = {
        change_id  => $change_id,
        id         => $id,
        status     => 'status' . $project_status,
        rank       => $project_status,
        project_id => $project->{id},
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $id,
            kind      => 'project_status',
        },
    );

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
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');

    $task_status++;

    my $ref = {
        change_id  => $change_id,
        id         => $id,
        status     => 'status' . $task_status,
        rank       => $task_status,
        project_id => $project->{id},
        def        => $task_status == 1,
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $id,
            kind      => 'task_status',
        },
    );

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
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');

    $issue_status++;

    my $ref = {
        change_id  => $change_id,
        id         => $id,
        status     => 'status' . $issue_status,
        rank       => $issue_status,
        project_id => $project->{id},
        def        => $issue_status == 1,
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $id,
            kind      => 'issue_status',
        },
    );

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
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');

    $task++;

    my $ref = {
        change_id => $change_id,
        id        => $id,
        title     => 'title' . $task,
        status_id => $status->{id},
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $id,
            kind      => 'task',
        },
    );

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
    my $change_id = shift || $db->currval('changes');
    my $id        = $db->nextval('topics');
    my $topic_id  = $db->nextval('topics');

    $issue++;

    my $ref = {
        change_id => $change_id,
        id        => $id,
        topic_id  => $topic_id,
        title     => 'title' . $issue,
        status_id => $status->{id},
    };

    $db->xdo(
        insert_into => 'func_new_topic',
        values      => {
            change_id => $change_id,
            id        => $topic_id,
            kind      => 'issue',
        },
    );

    $db->xdo(
        insert_into => 'func_new_issue',
        values      => $ref,
    );

    return $ref;
}

1;
__END__
