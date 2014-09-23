package App::bif::Context;
use strict;
use warnings;
use feature 'state';
use utf8;    # for render_table
use Carp ();
use Config::Tiny;
use File::HomeDir;
use Log::Any qw/$log/;
use Path::Tiny qw/path rootdir cwd/;
use Term::Size ();

our $VERSION = '0.1.0_28';

our ( $term_width, $term_height ) = Term::Size::chars(*STDOUT);
$term_width  ||= 80;
$term_height ||= 40;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $opts = shift || Carp::croak('missing ref');
    my $self = bless {}, $class;

    binmode STDIN,  ':encoding(utf8)';
    binmode STDOUT, ':encoding(utf8)';

    $self->{_bif_terminal}  = -t STDOUT;
    $self->{_bif_no_pager}  = !$self->{_bif_terminal} || $opts->{no_pager};
    $self->{_bif_repo_name} = delete $opts->{repo_name} || '.bif';

    # For Term::ANSIColor
    $ENV{ANSI_COLORS_DISABLED} = !$self->{_bif_terminal} || $opts->{no_color};

    if ( $opts->{debug} ) {
        require Log::Any::Adapter;
        $self->{_bif_log_any_adapter} = Log::Any::Adapter->set('Stdout');
        $self->start_pager();
    }

    $log->debugf( 'ctx: %s %s', (caller)[0], $opts );
    $log->debugf( 'ctx: terminal %dx%d', $term_width, $term_height );

    #    $self->find_user_repo;
    #    $self->find_repo($opts->{user_repo});

    # Merge in the command line options with the (user/repo) config
    $self->{$_} = $opts->{$_} for keys %$opts;
    return $self;
}

sub find_user_repo {
    my $self = shift;
    return $self->{_bif_user_repo} if $self->{_bif_user_repo};

    my $home_dir = File::HomeDir->my_home;
    my $user_repo = path( $home_dir, '.bifu' )->absolute;

    return $user_repo;
}

sub find_repo {
    my $self = shift;

    if ( $self->{user_repo} ) {
        my $repo = $self->find_user_repo || return;
        $log->debug( 'ctx: repo: ' . $repo );
        return $repo;
    }

    my $root = rootdir;
    my $try  = cwd;

    until ( $try eq $root ) {
        if ( -d ( my $repo = $try->child( $self->{_bif_repo_name} ) ) ) {
            $log->debug( 'ctx: repo: ' . $repo );

            return $repo;
        }
        $try = $try->parent;
    }

    return;
}

sub colours {
    my $self = shift;
    state $have_term_ansicolor = require Term::ANSIColor;

    map { $self->{_colours}->{$_} //= Term::ANSIColor::color($_) } @_;
    return map { $self->{_colours}->{$_} } @_;
}

sub header {
    my $self = shift;

    my ( $key, $val, $val2 ) = @_;
    return [
        ( $key ? $key . ':' : '' ) . $self->{_colours}->{reset},
        $val
          . (
            defined $val2 ? $self->{_colours}->{dark} . ' <' . $val2 . '>' : ''
          )
          . $self->{_colours}->{reset}
    ];
}

sub ago {
    my $self   = shift;
    my $time   = shift;
    my $offset = shift;

    state $have_posix         = require POSIX;
    state $have_time_piece    = require Time::Piece;
    state $have_time_duration = require Time::Duration;

    use locale;

    my $hours   = POSIX::floor( $offset / 60 / 60 );
    my $minutes = ( abs($offset) - ( abs($hours) * 60 * 60 ) ) / 60;
    my $dt      = Time::Piece->strptime( $time + $offset, '%s' );

    my $local =
      sprintf( '%s %+.2d%.2d', $dt->strftime('%a %F %R'), $hours, $minutes );

    return ( Time::Duration::ago( $self->{_now} - $time, 1 ), $local );
}

sub err {
    my $self = shift;
    Carp::croak('err($type, $msg, [$arg])') unless @_ >= 2;
    my $err = shift;
    my $msg = shift;

    die $msg if eval { $msg->isa('Bif::Error') };
    my ( $red, $reset ) = $self->colours(qw/red reset/);

    $msg = $red . 'fatal:' . $reset . ' ' . $msg . "\n";

    die Bif::Error->new( {%$self}, $err, $msg, @_ );
}

sub ok {
    my $self = shift;
    Carp::croak('ok($type, [$arg])') unless @_;
    my $ok = shift;
    return Bif::OK->new( {%$self}, $ok, @_ );
}

my $pager;

sub start_pager {
    my $self  = shift;
    my $lines = shift;
    return if $self->{_bif_no_pager} or $pager;

    if ( $lines && $lines <= $term_height ) {
        $log->debug("ctx: no start_pager ($lines <= $term_height)");
        return;
    }

    local $ENV{'LESS'} = '-FXeR';
    local $ENV{'MORE'} = '-FXer' unless $^O =~ /^MSWin/;

    require IO::Pager;
    $pager = IO::Pager->new(*STDOUT);
    $pager->binmode(':encoding(utf8)') if ref $pager;

    $log->debug('ctx: start_pager');

    $SIG{__DIE__} = sub {
        return if $^S or !defined $^S;
        $| = 1;
        STDOUT->flush;
        $self->end_pager();
    };

    return $pager;
}

sub end_pager {
    my $self = shift;
    return unless $pager;

    $log->debug('ctx: end_pager');
    $pager->close;
    $pager = undef;
    delete $SIG{__DIE__};
    return;
}

sub user_repo {
    my $self = shift;

    return $self->{_bif_user_repo} if $self->{_bif_user_repo};

    my $repo = $self->find_user_repo;

    return $self->err( 'UserRepoNotFound',
        'user repository not found (try "bif init -u -i")' )
      unless -e $repo;

    $self->{_bif_user_repo} = $repo;
    $log->debug( 'ctx: user_repo: ' . $repo );

    my $file = $repo->child('config');
    return $repo unless $file->exists;

    $self->{_bif_repo_config} = $file;

    my $conf = Config::Tiny->read( $file, 'utf8' )
      || return $self->err( 'ConfigNotFound',
        $file . ' ' . Config::Tiny->errstr );

    # Merge in the repo config with the current context (user) config
    while ( my ( $k1, $v1 ) = each %$conf ) {
        if ( ref $v1 eq 'HASH' ) {
            while ( my ( $k2, $v2 ) = each %$v1 ) {
                if ( $k1 eq '_' ) {
                    $self->{$k2} = $v2;
                }
                else {
                    $self->{$k1}->{$k2} = $v2;
                }
            }
        }
        else {
            $self->{$k1} = $v1;
        }
    }

    return $repo;
}

sub user_db {
    my $self = shift;
    return $self->{_bif_user_db} if $self->{_bif_user_db};

    my $dsn = 'dbi:SQLite:dbname=' . $self->user_repo->child('db.sqlite3');

    $log->debug( 'ctx: user_db: ' . $dsn );

    require Bif::DB;
    my $db = Bif::DB->connect( $dsn, undef, undef, undef, $self->{debug} );

    $log->debug( 'ctx: SQLite version: ' . $db->{sqlite_version} );
    $self->{_bif_user_db} = $db;
    return $db;
}

sub user_dbw {
    my $self = shift;
    return $self->{_bif_user_dbw} if $self->{_bif_user_dbw};

    my $dsn = 'dbi:SQLite:dbname=' . $self->user_repo->child('db.sqlite3');

    $log->debug( 'ctx: user_dbw: ' . $dsn );

    require Bif::DB;
    my $db = Bif::DBW->connect( $dsn, undef, undef, undef, $self->{debug} );

    $log->debug( 'ctx: SQLite version: ' . $db->{sqlite_version} );
    $self->{_bif_user_dbw} = $db;
    return $db;
}

sub repo {
    my $self = shift;

    return $self->{_bif_repo} if $self->{_bif_repo};

    my $repo = $self->find_repo
      || $self->err( 'RepoNotFound',
        'directory not found: ' . $self->{_bif_repo_name} );

    $self->{_bif_repo} = $repo;
    $log->debug( 'ctx: repo: ' . $repo );

    my $file = $repo->child('config');
    return $repo unless $file->exists;

    $log->debug( 'ctx: repo_conf: ' . $file );
    $self->{_bif_repo_config} = $file;

    my $conf = Config::Tiny->read( $file, 'utf8' )
      || return $self->err( 'ConfigNotFound',
        $file . ' ' . Config::Tiny->errstr );

    # Merge in the repo config with the current context (user) config
    while ( my ( $k1, $v1 ) = each %$conf ) {
        if ( ref $v1 eq 'HASH' ) {
            while ( my ( $k2, $v2 ) = each %$v1 ) {
                if ( $k1 eq '_' ) {
                    $self->{$k2} = $v2;
                }
                else {
                    $self->{$k1}->{$k2} = $v2;
                }
            }
        }
        else {
            $self->{$k1} = $v1;
        }
    }

    return $repo;
}

sub db {
    my $self = shift;
    return $self->{_bif_db} if $self->{_bif_db};

    my $repo = $self->repo;
    my $dsn  = 'dbi:SQLite:dbname=' . $repo->child('db.sqlite3');

    $log->debug( 'ctx: db: ' . $dsn );

    require Bif::DB;
    my $db = Bif::DB->connect( $dsn, undef, undef, undef, $self->{debug} );

    $log->debug( 'ctx: SQLite version: ' . $db->{sqlite_version} );
    $self->{_bif_db} = $db;
    return $db;
}

sub dbw {
    my $self = shift;
    return $self->{_bif_dbw} if $self->{_bif_dbw};

    my $repo = $self->repo;
    my $dsn  = 'dbi:SQLite:dbname=' . $repo->child('db.sqlite3');

    $log->debug( 'ctx: dbw: ' . $dsn );

    require Bif::DBW;
    my $dbw = Bif::DBW->connect( $dsn, undef, undef, undef, $self->{debug} );

    $log->debug( 'ctx: SQLite version: ' . $dbw->{sqlite_version} );
    $self->{_bif_dbw} = $dbw;
    return $dbw;
}

sub user_id {
    my $self = shift;
    my $id   = $self->db->xval(
        select => 'bif.identity_id',
        from   => 'bifkv bif',
        where  => { 'bif.key' => 'self' },
    );
    return $id;
}

sub uuid2id {
    my $self = shift;
    my $try  = shift;
    Carp::croak 'usage' if @_;

    return $try unless exists $self->{uuid} && $self->{uuid};
    my @list = $self->db->uuid2id($try);

    return $self->err( 'UuidNotFound', "uuid not found: $try" )
      unless @list;

    return $self->err( 'UuidAmbiguous', "ambiguious uuid: $try" )
      if @list > 1;

    return $list[0]->[0];
}

sub get_project {
    my $self = shift;
    my $path = shift;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;

    my $hub;
    if ( $path =~ m/(.*)@(.*)/ ) {
        $path = $1;
        $hub  = $2;
    }

    my @matches = $db->get_projects( $path, $hub );

    if ( 0 == @matches ) {
        return $self->err( 'ProjectNotFound', "project not found: $path" )
          unless $hub;

        return $self->err( 'ProjectNotFound', "project not found: $path\@$hub" )
          if eval { $self->get_hub($hub) };

        return $self->err( 'HubNotFound',
            "hub not found: $hub (for $path\@$hub)" );
    }
    elsif ( 1 == @matches ) {
        return $matches[0];
    }
    elsif ( not defined $matches[0]->{hub_name} ) {
        return $matches[0];
    }

    return $self->err( 'AmbiguousPath',
        "ambiguous path \"$path\" matches the following:\n" . '    '
          . join( "\n    ", map { "$path\@$_->{hub_name}" } @matches ) );
}

sub get_hub {
    my $self = shift;
    my $name = shift;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;

    my ($hub) = $db->xhashref(
        select           => [qw/h.id h.name t.kind t.uuid t.first_change_id/],
        from             => 'hubs h',
        inner_join       => 'topics t',
        on               => 't.id = h.id',
        where            => { 'h.name' => $self->uuid2id($name) },
        union_all_select => [qw/h.id h.name t.kind t.uuid t.first_change_id/],
        from             => 'hub_repos hr',
        inner_join       => 'hubs h',
        on               => 'h.id = hr.hub_id',
        inner_join       => 'topics t',
        on               => 't.id = h.id',
        where            => { 'hr.location' => $name },
    );

    return $self->err( 'HubNotFound', "hub not found: $name" )
      unless $hub;

    return $hub;
}

sub render_table {
    my $self   = shift;
    my $format = shift;
    my $header = shift;
    my $data   = shift;
    my $indent = shift || 0;

    my ( $white, $dark, $reset ) = $self->colours(qw/white dark reset/);
    require Text::FormatTable;

    my $table = Text::FormatTable->new($format);

    if ($header) {
        $header->[$_] = uc $header->[$_] for -1 .. $#$header;
        $header->[0] = $white . $header->[0];
        push( @$header, ( pop @$header ) . $reset );
        $table->head(@$header);
    }

    foreach my $row (@$data) {
        $table->row(@$row);
    }

    return $table->render($term_width) unless $indent;

    my $str = $table->render( $term_width - $indent );

    my $prefix = ' ' x $indent;
    $str =~ s/^/$prefix/gm;
    return $str;
}

sub prompt_edit {
    my $self = shift;
    my %args = (
        opts           => {},
        abort_on_empty => 1,
        val            => '',
        @_,
    );

    $args{txt} //= "\n";
    $args{txt} .= " 
# Please enter your message. Lines starting with '#'
# are ignored. Empty content aborts.
#
";

    foreach my $key ( sort keys %{ $args{opts} } ) {
        next if $key =~ m/^_/;
        next unless defined $args{opts}->{$key};
        $args{txt} .= "#     $key: $args{opts}->{$key}\n";
    }

    require IO::Prompt::Tiny;
    if ( IO::Prompt::Tiny::_is_interactive() ) {
        require Proc::InvokeEditor;
        $args{val} = Proc::InvokeEditor->edit( $args{val} || $args{txt} );
        utf8::decode( $args{val} );
    }

    $args{val} =~ s/^#.*//gm;
    $args{val} =~ s/^\n+//s;
    $args{val} =~ s/\n*$/\n/s;

    if ( $args{abort_on_empty} ) {
        return $self->err( 'EmptyContent', 'aborting due to empty content.' )
          if $args{val} =~ m/^[\s\n]*$/s;
    }

    return $args{val};
}

sub lprint {
    my $self = shift;
    my $msg  = shift;
    my $old  = $self->{_bif_print} //= '';

    if ( $pager or $self->{debug} ) {
        return print $msg . "\n";
    }

    local $| = 1;

    my $chars = print ' ' x length($old), "\b" x length($old), $msg, "\r";
    $self->{_bif_print} = $msg =~ m/\n/ ? '' : $msg;
    return $chars;
}

sub get_change {
    my $self            = shift;
    my $token           = shift // return;
    my $first_change_id = shift;

    return $self->err( 'ChangeNotFound', "change not found: $token" )
      unless $token =~ m/^c(\d+)$/;

    my $id = $1;
    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;

    my $data = $db->xhashref(
        select => [ 'c.id AS id', 'c.uuid AS uuid', ],
        from   => 'changes c',
        where => { 'c.id' => $id },
    );

    return $self->err( 'ChangeNotFound', "change not found: $token" )
      unless $data;

    if ($first_change_id) {
        my $t = $db->xhashref(
            select => 1,
            from   => 'changes_tree ct',
            where  => {
                'ct.child'  => $id,
                'ct.parent' => $first_change_id,
            },
        );

        return $self->err( 'FirstChangeMismatch',
            'first change id mismatch: c%d / c%d',
            $first_change_id, $id )
          unless $t;
    }

    return $data;
}

sub get_topic {
    my $self  = shift;
    my $token = shift // return;
    my $kind  = shift;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;

    state $have_qv = DBIx::ThinSQL->import(qw/ qv bv /);

    if ( $token =~ m/^\d+$/ ) {
        my $data = $db->xhashref(
            select => [
                't.id AS id',
                't.kind AS kind',
                't.uuid AS uuid',
                't.first_change_id AS first_change_id',
                qv(undef)->as('project_issue_id'),
                qv(undef)->as('project_id'),
            ],
            from  => 'topics t',
            where => [ 't.id = ', qv($token), ' AND t.kind != ', qv('issue') ],
            union_all_select => [
                't.id AS id',
                't.kind AS kind',
                't.uuid AS uuid',
                't.first_change_id AS first_change_id',
                'pi.id AS project_issue_id',
                'pi.project_id',
            ],
            from       => 'project_issues pi',
            inner_join => 'topics t',
            on         => 't.id = pi.issue_id',
            where      => { 'pi.id' => $token },
            order_by   => 'project_issue_id DESC',
            limit      => 1,
        );

        return $self->err( 'WrongKind', 'topic (%s) is not a %s: %d',
            $data->{kind}, $kind, $token )
          if $data && $kind && $kind ne $data->{kind};

        return $data if $data;
    }

    my $pinfo = eval { $self->get_project($token) };
    die $@ if ( $@ && $@->isa('Bif::Error::AmbiguousPath') );
    return $pinfo if $pinfo;

    $kind ||= 'topic';
    return $self->err( 'TopicNotFound', "$kind not found: $token" );
}

sub new_change {
    my $self = shift;
    my %vals = @_;

    my $dbw    = $self->dbw;
    my $id     = ( delete $vals{id} ) // $dbw->nextval('changes');
    my $author = delete $vals{author};
    my $email  = delete $vals{email};

    state $have_dbix = DBIx::ThinSQL->import(qw/ qv coalesce /);

    my $res = $dbw->xdo(
        insert_into => [ 'changes', 'id', 'identity_id', sort keys %vals ],
        select      => [
            qv($id), 'bif.identity_id',
            map { qv( $vals{$_} ) } sort keys %vals
        ],
        from  => 'bifkv bif',
        where => { 'bif.key' => 'self' },
    );

    return $self->err( 'NoSelfIdentity', 'no "self" identity' )
      unless $res > 0;
    return $id;
}

sub DESTROY {
    my $self = shift;
    Log::Any::Adapter->remove( $self->{_bif_log_any_adapter} )
      if $self->{_bif_log_any_adapter};
}

package Bif::OK;
use overload
  bool     => sub { 1 },
  '""'     => \&as_string,
  fallback => 1;

sub new {
    my $proto = shift;
    my $self  = shift;
    $self->{_bif_ok_type} = shift || Carp::confess('missing type');
    $self->{_bif_ok_msg}  = shift || '';
    $self->{_bif_ok_msg} = sprintf( $self->{_bif_ok_msg}, @_ ) if @_;

    my $class = $proto . '::' . $self->{_bif_ok_type};
    {
        no strict 'refs';
        *{ $class . '::ISA' } = [$proto];
    }

    return bless $self, $class;
}

sub as_string {
    my $self = shift;
    return $self->{_bif_ok_msg} || ref $self;
}

package Bif::Error;
use overload
  bool     => sub { 1 },
  fallback => 1;

our @ISA = ('Bif::OK');

1;

__END__

=head1 NAME

App::bif::Context - A base class for App::bif::* commands

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    # In App/bif/command/name.pm
    use strict;
    use warnings;
    use parent 'App::bif::Context';

    sub run {
        my $self  = __PACKAGE__->new(shift);
        my $db   = $self->db;
        my $data = $db->xarrayref(...);

        return $self->err( 'SomeFailure', 'something failed' )
          if ($self->{command_option});

        $self->start_pager;

        print $self->render_table(
            ' r  l  l ',
            [qw/ ID Title Status /],
            $data, 
        );

        $self->end_pager;

        return $self->ok('CommandName');
    }

=head1 DESCRIPTION

B<App::bif::Context> provides a context/configuration class for bif
commands to inherit from. It is constructed as a blessed hashref, and
commands are expected to grab configuration keys and call methods on
it.

The above synopsis is the basic template for any bif command. At run
time the C<run> function is called by C<OptArgs::dispatch> with the
options hashref as the first argument. The first thing the bif command
should do is instantiate itself to set up a bif context which sets up
logging and merges the user and repository configurations with the
command-line options.

B<App::bif::Context> sets the encoding of C<STDOUT> and C<STDIN> to
utf-8 when it is loaded.

=head1 CONSTRUCTOR

=over 4

=item __PACKAGE__->new( $opts )

Initializes the common elements of all bif scripts. Requires the
options hashref as provided by L<OptArgs> but also returns it.

=over

=item * Sets the package variable C<$App::bif::Context::STDOUT_TERMINAL> to
true if C<STDOUT> is connected to a terminal.

=item * Sets the environment variable C<ANSI_COLORS_DISABLED> to
1 if C<STDOUT> is I<not> connected to a terminal, in order to disable
L<Term::ANSIColor> functions.

=item * Starts a pager if C<--debug> is true, unless C<--no-pager> is
also set to true or C<STDOUT> is not connected to a terminal.

=item * Adds unfiltered logging via L<Log::Any::Adapter::Stdout>.

=back

=back


=head1 METHODS

=over 4

=item colours( @colours ) -> @codes

Calls C<color()> from L<Term::ANSIColor> on every string from
C<@colours> and returns the results. Returns empty strings if the
environment variable C<$ANSI_COLORS_DISABLED> is true (set by the
C<--no-color> option).

=item header( $key, $val, $val2 ) -> ArrayRef

Returns a two or three element arrayref formatted as so:

    ["$key:", $val, "<$val2>"]

Colours are used to make the $val2 variable darker. The result is
generally used when rendering tables by log and show commands.

=item ago( $epoch, $offset ) -> $string, $timestamp

Uses L<Time::Duration> to generate a human readable $string indicating
how long ago UTC $epoch was (with $offset in +/- seconds) plus a
regular timestamp string.

=item err( $err, $message, [ @args ])

Throws an exception that stringifies to C<$message> prefixed with
"fatal: ". The exception is an object from the C<Bif::Error::$err>
class which is used by test scripts to reliably detect the type of
error. If C<@args> exists then C<$message> is assumed to be a format
string to be converted with L<sprintf>.

=item ok( $type, [ $arg ])

Returns a C<Bif::OK::$type> object, either as a reference to C<$arg> or
as a reference to the class name. Every App::bif::* command should
return such an object, which can be tested for by tests.

=item start_pager([ $rows ])

Start a pager (less, more, etc) on STDOUT using L<IO::Pager>, provided
that C<--no-pager> has not been used. The pager handle encoding is set
to utf-8. If the optional C<$rows> has been given then the pager will
only be started if L<Term::Size> reports the height of the terminal as
being less than C<$rows>.

=item end_pager

Stops the pager on STDOUT if it was previously started.

=item user_repo -> Path::Tiny

Returns the location of the user repository directory.  Raises a
'UserRepoNotFound' error on failure.

=item user_db -> Bif::DB::db

Returns a read-only handle for the SQLite database containing
user-specific data.

=item user_dbw -> Bif::DBW::db

Returns a read-write handle for the SQLite database containing
user-specific data.

=item repo -> Path::Tiny

Return the path to the first '.bif' directory found starting from the
current working directory and searching upwards. Raises a
'RepoNotFound' error on failure.

=item db -> Bif::DB::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>). The handle is only good for read operations -
use C<$self->dbw> when inserting,updating or deleting from the
database.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<bif_db>, in order to keep startup time short for cases
such as when the repository is not found.

=item dbw -> Bif::DBW::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>). The handle is good for INSERT, UPDATE and DELETE
operations.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<$self->dbw>, in order to keep startup time short for
cases such as when the repository is not found.

=item user_id -> Int

Returns the topic ID for the user (self) identity.

=item uuid2id( $try ) -> Int

Returns C<$try> unless a C<< $self->{uuid} >> option has been set.
Returns C<< Bif::DB->uuid2id($try) >> if the lookup succeeds or else
raises an error.

=item get_project( $path ) -> HashRef

Calls C<get_project> from C<Bif::DB> and returns a single hashref.
Raises an error if no project is found.  C<$path> is interpreted as a
string of the form C<PROJECT[@HUB]>.

=item get_hub( $name ) -> HashRef

Looks up the hub where $name is either the topic ID, the hub name, or a
hub location and returns the equivalent of C<get_topic($ID)> plus the
hub name.

=item render_table( $format, \@header, \@data, [ $indent ] ) -> Str

Uses L<Text::FormatTable> to construct a table of <@data>, aligned and
spaced according to C<$format>, preceded by a C<@header>. If C<$indent>
is greater than zero then the entire table is indented by that number
of spaces.

=item prompt_edit( %options ) -> Str

If the environment is interactive this function will invoke an editor
and return the result. All comment lines (beginning with '#') are
removed. TODO: describe %options.

=item lprint( $msg ) -> Int

If a pager is not active this method prints C<$msg> to STDOUT and
returns the cursor to the beginning of the line.  The next call
over-writes the previously printed text before printing the new
C<$msg>. In this way a continually updating status can be displayed.

=item get_change( $CID, [$first_change_id] ) -> HashRef

Looks up the change identified by C<$CID> (of the form "c23") and
returns a hash reference containg the following keys:

=over

=item * id - the change ID

=item * uuid - the universally unique identifier of the change

=back

An ChangeNotFound error will be raised if the change does not exist. If
C<$first_change_id> is provided then a check will be made to ensure
that that C<$CID> is a child of <$first_change_id> with a
FirstChangeMismatch error thrown if that is not the case.

=item get_topic( $TOKEN ) -> HashRef

Looks up the topic identified by C<$TOKEN> and returns undef or a hash
reference containg the following keys:

=over

=item * id - the topic ID

=item * first_change_id - the change_id that created the topic

=item * kind - the type of the topic

=item * uuid - the universally unique identifier of the topic

=back

If the found topic is an issue then the following keys will also
contain valid values:

=over

=item * project_issue_id - the project-specific topic ID

=item * project_id - the project ID matching the project_issue_id

=back

=item new_change( %args ) -> Int

Creates a new row in the changes table according to the content of
C<%args> (must include at least a C<message> value) and the current
context (identity). Returns the integer ID of the change.

=back

=head1 SEE ALSO

L<Bif::DB>, L<Bif::DBW>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

