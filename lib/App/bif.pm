package App::bif;
use strict;
use warnings;
use feature 'state';
use utf8;    # for render_table
use Bif::Mo;
use Carp ();
use Config::Tiny;
use File::HomeDir;
use Log::Any qw/$log/;
use Path::Tiny qw/path rootdir cwd/;

our $VERSION = '0.1.4';
our $pager;

sub MSWin32 { $^O eq 'MSWin32' }

has db => (
    is      => 'ro',
    default => \&_build_db,
);

has dbw => (
    is      => 'rw',           # for bif-new-repo?
    default => \&_build_dbw,
);

has _colours => (
    is      => 'ro',
    default => {},
);

has config => (
    is      => 'ro',
    default => {},
);

has no_pager => (
    is      => 'rw',
    default => sub {
        my $self = shift;
        return ( !-t STDOUT ) || $self->opts->{no_pager};
    },
);

has now => (
    is      => 'ro',
    default => sub { time },
);

has opts => (
    is       => 'ro',
    required => 1,
);

has repo => (
    is      => 'rw',            # needed by init
    default => \&_build_repo,
);

has term_width => (
    is      => 'ro',
    default => sub {
        my $width;
        if (MSWin32) {
            require Term::Size::Win32;
            $width = ( Term::Size::Win32::chars(*STDOUT) )[0] || 80;
        }
        else {
            require Term::Size::Perl;
            $width = ( Term::Size::Perl::chars(*STDOUT) )[0] || 80;
        }
        $log->debugf( 'bif: terminal width %d', $width );
        return $width;
    },
);

has term_height => (
    is      => 'ro',
    default => sub {
        my $height;
        if (MSWin32) {
            require Term::Size::Win32;
            $height = ( Term::Size::Win32::chars(*STDOUT) )[1] || 40;
        }
        else {
            require Term::Size::Perl;
            $height = ( Term::Size::Perl::chars(*STDOUT) )[1] || 40;
        }
        $log->debugf( 'bif: terminal height %d', $height );
        return $height;
    },
);

has user_repo => (
    is      => 'ro',
    default => \&_build_user_repo,
);

has user_db => (
    is      => 'ro',
    default => \&_build_user_db,
);

has user_dbw => (
    is      => 'ro',
    default => \&_build_user_dbw,
);

sub BUILD {
    my $self = shift;
    my $opts = $self->opts;

    # For Term::ANSIColor
    $ENV{ANSI_COLORS_DISABLED} = $opts->{no_color} || !-t STDOUT;

    binmode STDIN,  ':encoding(utf8)';
    binmode STDOUT, ':encoding(utf8)';

    if ( $opts->{debug} ) {
        require Log::Any::Adapter;
        Log::Any::Adapter->set('+App::bif::LAA');
        $self->start_pager();
    }

    $log->debugf( 'bif: %s %s', ref $self, $opts );

    return;
}

sub _build_user_repo {
    my $self = shift;
    my $repo = path( File::HomeDir->my_home, '.bifu' )->absolute;

    $self->err( 'UserRepoNotFound',
        'user repository not found (try "bif init -u -i")' )
      unless -d $repo;

    $log->debug( 'bif: user_repo: ' . $repo );

    my $file = $repo->child('config');
    return $repo unless $file->exists;

    my $config = $self->config;
    my $conf = Config::Tiny->read( $file, 'utf8' )
      || return $self->err( 'ConfigNotFound',
        $file . ' ' . Config::Tiny->errstr );

    # Merge in the repo config with the current context (user) config
    while ( my ( $k1, $v1 ) = each %$conf ) {
        if ( ref $v1 eq 'HASH' ) {
            while ( my ( $k2, $v2 ) = each %$v1 ) {
                if ( $k1 eq '_' ) {
                    $config->{$k2} = $v2;
                }
                else {
                    $config->{$k1}->{$k2} = $v2;
                }
            }
        }
        else {
            $config->{$k1} = $v1;
        }
    }

    return $repo;
}

sub _build_repo {
    my $self = shift;
    $self->user_repo;    # build user repo first

    my $repo = $self->find_repo('.bif')
      || $self->err( 'RepoNotFound', 'directory not found: .bif' );

    $log->debug( 'bif: repo: ' . $repo );

    my $file = $repo->child('config');
    return $repo unless $file->exists;

    $log->debug( 'bif: repo_conf: ' . $file );

    # Trigger user config
    $self->user_repo;

    my $config = $self->config;
    my $conf = Config::Tiny->read( $file, 'utf8' )
      || return $self->err( 'ConfigNotFound',
        $file . ' ' . Config::Tiny->errstr );

    # Merge in the repo config with the current context (user) config
    while ( my ( $k1, $v1 ) = each %$conf ) {
        if ( ref $v1 eq 'HASH' ) {
            while ( my ( $k2, $v2 ) = each %$v1 ) {
                if ( $k1 eq '_' ) {
                    $config->{$k2} = $v2;
                }
                else {
                    $config->{$k1}->{$k2} = $v2;
                }
            }
        }
        else {
            $config->{$k1} = $v1;
        }
    }

    return $repo;
}

sub _build_user_db {
    my $self = shift;
    my $dsn  = 'dbi:SQLite:dbname=' . $self->user_repo->child('db.sqlite3');

    require Bif::DB;
    my $db =
      Bif::DB->connect( $dsn, undef, undef, undef, $self->opts->{debug} );

    $log->debug( 'bif: user_db: ' . $dsn );
    $log->debug( 'bif: SQLite version: ' . $db->{sqlite_version} );

    return $db;
}

sub _build_user_dbw {
    my $self = shift;
    my $dsn  = 'dbi:SQLite:dbname=' . $self->user_repo->child('db.sqlite3');

    require Bif::DBW;
    my $dbw =
      Bif::DBW->connect( $dsn, undef, undef, undef, $self->opts->{debug} );

    $log->debug( 'bif: user_dbw: ' . $dsn );
    $log->debug( 'bif: SQLite version: ' . $dbw->{sqlite_version} );

    return $dbw;
}

sub _build_db {
    my $self = shift;
    my $dsn  = 'dbi:SQLite:dbname=' . $self->repo->child('db.sqlite3');

    require Bif::DB;
    my $db =
      Bif::DB->connect( $dsn, undef, undef, undef, $self->opts->{debug} );

    $log->debug( 'bif: db: ' . $dsn );
    $log->debug( 'bif: SQLite version: ' . $db->{sqlite_version} );

    return $db;
}

sub _build_dbw {
    my $self = shift;
    my $dsn  = 'dbi:SQLite:dbname=' . $self->repo->child('db.sqlite3');

    require Bif::DBW;
    my $dbw =
      Bif::DBW->connect( $dsn, undef, undef, undef, $self->opts->{debug} );

    $log->debug( 'bif: dbw: ' . $dsn );
    $log->debug( 'bif: SQLite version: ' . $dbw->{sqlite_version} );

    return $dbw;
}

### class methods ###

sub dispatch {
    my $self  = shift;
    my $class = shift;
    my $ref   = shift || {};

    Carp::croak($@) unless eval "require $class;";

    return $class->new( %$self, %$ref )->run;
}

# Run user defined aliases
sub run {
    my $self  = shift;
    my $opts  = $self->opts;
    my @cmd   = @{ $opts->{alias} };
    my $alias = shift @cmd;

    use File::HomeDir;
    use Path::Tiny;

    my $repo = path( File::HomeDir->my_home, '.bifu' );
    die usage(qq{unknown COMMAND or ALIAS "$alias"}) unless -d $repo;

    # Trigger user config
    $self->user_repo;
    my $str = $self->config->{'user.alias'}->{$alias}
      or die usage(qq{unknown COMMAND or ALIAS "$alias"});

    # Make sure these options are correctly passed through (or not)
    delete $opts->{alias};
    $opts->{debug}     = undef if exists $opts->{debug};
    $opts->{no_pager}  = undef if exists $opts->{no_pager};
    $opts->{no_color}  = undef if exists $opts->{no_color};
    $opts->{user_repo} = undef if exists $opts->{user_repo};

    unshift( @cmd, split( ' ', $str ) );

    use OptArgs qw/class_optargs/;
    my ( $class, $newopts ) = OptArgs::class_optargs( 'App::bif', $opts, @cmd );

    return $class->new(
        opts      => $newopts,
        user_repo => $self->user_repo,
    )->run;
}

sub find_repo {
    my $self = shift;
    my $name = shift;

    if ( $self->opts->{user_repo} ) {
        my $repo = $self->user_repo || return;
        return $repo;
    }

    my $root = rootdir;
    my $try  = cwd;

    until ( $try eq $root ) {
        if ( -d ( my $repo = $try->child($name) ) ) {
            return $repo;
        }
        $try = $try->parent;
    }

    return;
}

sub colours {
    my $self = shift;
    state $have_term_ansicolor = require Term::ANSIColor;

    return map { '' } @_ if $self->opts->{no_color};

    my $ref = $self->_colours;
    map { $ref->{$_} //= Term::ANSIColor::color($_) } @_;
    return map { $ref->{$_} } @_ if wantarray;
    return $ref->{ $_[0] };
}

sub header {
    my $self = shift;
    state $reset = $self->colours(qw/reset/);
    state $dark  = $self->colours(qw/dark/);

    my ( $key, $val, $val2 ) = @_;
    return [
        ( $key ? $key . ':' : '' ) . $reset,
        $val . ( defined $val2 ? $dark . ' <' . $val2 . '>' : '' ) . $reset
    ];
}

sub ctime_ago {
    my $self = shift;
    my $row  = shift;

    state $have_time_piece    = require Time::Piece;
    state $have_time_duration = require Time::Duration;

    use locale;

    return (
        Time::Duration::ago( $row->{ctime_age}, 1 ),
        Time::Piece->strptime( $row->{ctime} + $row->{ctimetz}, '%s' )
          ->strftime('%a %F %R ') . $row->{ctimetzhm}
    );
}

sub mtime_ago {
    my $self = shift;
    my $row  = shift;

    state $have_time_piece    = require Time::Piece;
    state $have_time_duration = require Time::Duration;

    use locale;

    return (
        Time::Duration::ago( $row->{mtime_age}, 1 ),
        Time::Piece->strptime( $row->{mtime} + $row->{mtimetz}, '%s' )
          ->strftime('%a %F %R ') . $row->{mtimetzhm}
    );
}

sub err {
    my $self = shift;
    Carp::croak('err($type, $msg, [$arg])') unless @_ >= 2;
    my $err = shift;
    my $msg = shift;

    die $msg if eval { $msg->isa('Bif::Error') };
    my ( $red, $reset ) = $self->colours(qw/red reset/);

    $msg = $red . 'error:' . $reset . ' ' . $msg . "\n";

    die Bif::Error->new( $self->opts, $err, $msg, @_ );
}

sub ok {
    my $self = shift;
    Carp::croak('ok($type, [$arg])') unless @_;
    my $ok = shift;
    return Bif::OK->new( $self->opts, $ok, @_ );
}

sub start_pager {
    my $self  = shift;
    my $lines = shift;

    return if $pager or $self->no_pager;

    if ($lines) {
        my $term_height = $self->term_height;
        if ( $lines <= $term_height ) {
            $log->debug("bif: no start_pager ($lines <= $term_height)");
            return;
        }
    }

    local $ENV{'LESS'} = '-FXeR';
    local $ENV{'MORE'} = '-FXer' unless MSWin32;

    require App::bif::Pager;
    $pager = App::bif::Pager->new;

    $log->debugf( 'bif: start_pager (fileno: %d)', fileno( $pager->fh ) );

    return $pager;
}

sub end_pager {
    my $self = shift;
    return unless $pager;

    $log->debug('bif: end_pager');
    $pager = undef;
    return;
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
    my $try  = shift // Carp::croak 'uuid2id needs defined';
    my $opts = $self->opts;
    Carp::croak 'usage' if @_;

    return $try unless exists $opts->{uuid} && $opts->{uuid};
    my @list = $self->db->uuid2id($try);

    return $self->err( 'UuidNotFound', "uuid not found: $try" )
      unless @list;

    return $self->err( 'UuidAmbiguous',
        "ambiguious uuid: $try\n    "
          . join( "\n    ", map { "$_->[1] -> ID:$_->[0]" } @list ) )
      if @list > 1;

    return $list[0]->[0];
}

sub get_project {
    my $self = shift;
    my $path = shift;
    my $db   = $self->db;

    my $hub;
    if ( $path =~ m/(.*?)\/(.*)/ ) {
        $hub  = $1;
        $path = $2;
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
    my $db   = $self->db;

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

    my ( $white, $dark, $reset ) = $self->colours(qw/yellow dark reset/);
    require Text::FormatTable;

    my $table = Text::FormatTable->new($format);

    if ($header) {
        $header->[0] = $white . $header->[0];
        push( @$header, ( pop @$header ) . $reset );
        $table->head(@$header);
    }

    foreach my $row (@$data) {
        $table->row(@$row);
    }

    my $term_width = $self->term_width;
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
        require App::bif::Editor;
        $args{val} = App::bif::Editor->new( txt => $args{txt} )->result;
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

my $old = '';

sub lprint {
    my $self = shift;
    my $msg  = shift;

    if ( $pager or $self->opts->{debug} ) {
        return print $msg . "\n";
    }

    local $| = 1;

    my $chars = print ' ' x length($old), "\b" x length($old), $msg, "\r";
    $old = $msg =~ m/\n/ ? '' : $msg;
    return $chars;
}

sub get_change {
    my $self            = shift;
    my $token           = shift // Carp::croak('get_change needs defined');
    my $first_change_id = shift;

    return $self->err( 'ChangeNotFound', "change not found: $token" )
      unless $token =~ m/^c(\d+)$/;

    my $id = $1;
    my $db = $self->db;

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
    my $self = shift;

    my $token = shift // Carp::confess('get_topic needs defined');
    my $kind  = shift;
    my $db    = $self->db;

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

    return $self->err( 'NoSelfIdentity',
        'no "self" identity ' . join( ' ', caller ) )
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
    my $opts  = shift;
    $opts->{_bif_ok_type} = shift || Carp::confess('missing type');
    $opts->{_bif_ok_msg}  = shift || '';
    $opts->{_bif_ok_msg} = sprintf( $opts->{_bif_ok_msg}, @_ ) if @_;

    my $class = $proto . '::' . $opts->{_bif_ok_type};
    {
        no strict 'refs';
        *{ $class . '::ISA' } = [$proto];
    }

    return bless {%$opts}, $class;
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

=for bif-doc #perl

App::bif - A base class for App::bif::* commands

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    # In App/bif/command/name.pm
    use strict;
    use warnings;
    use parent 'App::bif';

    sub run {
        my $self = shift;
        my $db   = $self->db;
        my $data = $db->xarrayref(...);

        return $self->err( 'SomeFailure', 'something failed' )
          if ( $self->{command_option} );

        $self->start_pager;

        print $self->render_table( ' r  l  l ',
            [qw/ ID Title Status /], $data, );



        return $self->ok('CommandName');
    }

=head1 DESCRIPTION

B<App::bif> provides a context/configuration class for bif commands to
inherit from.  The above synopsis is the basic template for any bif
command. At run time the C<run> method is called.

B<App::bif> sets the encoding of C<STDOUT> and C<STDIN> to utf-8 when
it is loaded.

=head1 CONSTRUCTOR

=over 4

=item new( opts => $opts )

Initializes the common elements of all bif scripts. Requires the
options hashref as provided by L<OptArgs> but also returns it.

=over

=item * Sets the package variable C<$App::bif::STDOUT_TERMINAL> to
true if C<STDOUT> is connected to a terminal.

=item * Sets the environment variable C<ANSI_COLORS_DISABLED> to
1 if C<STDOUT> is I<not> connected to a terminal, in order to disable
L<Term::ANSIColor> functions.

=item * Starts a pager if C<--debug> is true, unless C<--no-pager> is
also set to true or C<STDOUT> is not connected to a terminal.

=item * Adds unfiltered logging via L<Log::Any::Adapter::Stdout>.

=back

=back


=head1 ATTRIBUTES

To be documented.

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

=item dispatch($class, $attrs)

Loads the bif class C<$class>, creates a new object populated with the
attributes from C<$self> plus the attributes in the HASHref C<$attrs>
and runs the C<run()> method.

=item run

B<App::bif> is responsible for expanding user aliases and redispatching
to the actual command. Needs to be documented .... sorry.

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



