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
      new_test_project
      new_test_project_status
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
our $SRC_DIR   = path(__FILE__)->parent(4)->absolute;
our $SHARE_DIR = path(__FILE__)->parent(4)->child('share')->absolute;

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

my $project = 0;

sub new_test_project {
    $project++;
    my $db        = shift;
    my $update_id = shift || $db->currval('updates');
    my $ref       = {
        update_id => $update_id,
        id        => $db->nextval('topics'),
        name      => 'todo' . $project,
        title     => 'title' . $project,
    };

    $db->xdo(
        insert_into => 'func_new_project',
        values      => $ref,
    );
    return $ref;
}

my $project_status = 0;

sub new_test_project_status {
    my $db         = shift;
    my $project_id = shift;
    my $update_id  = shift || $db->currval('updates');

    my $ref = {
        update_id  => $update_id,
        id         => $db->nextval('topics'),
        status     => 'status' . $project,
        rank       => $project,
        project_id => $project_id,
    };

    $db->xdo(
        insert_into => 'func_new_project_status',
        values      => $ref,
    );

    return $ref;
}

1;
__END__
