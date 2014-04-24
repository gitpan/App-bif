package App::bif::Context;
use strict;
use warnings;
use utf8;    # for render_table
use Carp ();
use Config::Tiny;
use File::HomeDir;
use Log::Any qw/$log/;
use Path::Tiny qw/path rootdir cwd/;

our $VERSION = '0.1.0_14';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $opts = shift || Carp::croak('missing ref');
    my $self = bless {}, $class;

    binmode STDIN,  ':encoding(utf8)';
    binmode STDOUT, ':encoding(utf8)';

    $self->{_bif_terminal} = -t STDOUT;
    $self->{_bif_no_pager} = !$self->{_bif_terminal} || $opts->{no_pager};

    # For Term::ANSIColor
    $ENV{ANSI_COLORS_DISABLED} = !$self->{_bif_terminal} || $opts->{no_color};

    if ( $opts->{debug} ) {
        require Log::Any::Adapter;
        Log::Any::Adapter->set('Stdout');
        $self->start_pager();
    }

    $log->debugf( 'ctx: %s %s', (caller)[0], $opts );

    $self->find_user_conf;
    $self->find_repo;

    # Merge in the command line options with the (user/repo) config
    $self->{$_} = $opts->{$_} for keys %$opts;
    return $self;
}

sub find_user_conf {
    my $self = shift;

    my $config_dir =
      File::HomeDir->my_app_config( 'bif-user', { create => 1 } );
    my $file = path( $config_dir, 'config' );

    $self->{_bif_user_config} = $file;
    $log->debug( 'ctx: user_conf: ' . $file );

    if ( -e $file ) {
        my $conf = Config::Tiny->read($file)
          || confess $Config::Tiny::errstr;

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
        return;
    }

    require IO::Prompt::Tiny;
    print "Initial Setup, please provide the following details:\n";

    my $git_conf_file = path( File::HomeDir->my_home, '.gitconfig' );
    my $git_conf = Config::Tiny->read($git_conf_file) || {};

    my $conf = Config::Tiny->new;
    ( my $name  = $git_conf->{user}->{name}  || 'Your Name' ) =~ s/(^")|("$)//g;
    ( my $email = $git_conf->{user}->{email} || 'your@email.adddr' ) =~
      s/(^")|("$)//g;

    $conf->{user}->{name}  = IO::Prompt::Tiny::prompt( 'Name:',  $name );
    $conf->{user}->{email} = IO::Prompt::Tiny::prompt( 'Email:', $email );
    $conf->{'user.alias'}->{l}   = 'list topics --status open';
    $conf->{'user.alias'}->{lt}  = 'list tasks --status open';
    $conf->{'user.alias'}->{lts} = 'list tasks --status stalled';
    $conf->{'user.alias'}->{li}  = 'list issues --status open';
    $conf->{'user.alias'}->{lis} = 'list issues --status stalled';
    $conf->{'user.alias'}->{ltc} = 'list projects --status closed';
    $conf->{'user.alias'}->{lp}  = 'list projects --status run';

    print "Writing $file\n";
    $conf->write($file);

    $self->{$_} ||= $conf->{$_} for keys %$conf;

    return;
}

sub File::HomeDir::my_app_config {
    my $params = ref $_[-1] eq 'HASH' ? pop : {};
    my $dist = pop
      or Carp::croak("The my_app_config method requires an argument");

    # not all platforms support a specific my_config() method
    my $config =
        $File::HomeDir::IMPLEMENTED_BY->can('my_config')
      ? $File::HomeDir::IMPLEMENTED_BY->my_config
      : $File::HomeDir::IMPLEMENTED_BY->my_documents;

    # If neither configdir nor my_documents is defined, there's
    # nothing we can do: bail out and return nothing...
    return undef unless defined $config;

    # On traditional unixes, hide the top-level dir
    my $etc =
      $config eq home()
      ? File::Spec->catdir( $config, '.' . $dist )
      : File::Spec->catdir( $config, $dist );

    # directory exists: return it
    return $etc if -d $etc;

    # directory doesn't exist: check if we need to create it...
    return undef unless $params->{create};

    # user requested directory creation
    require File::Path;
    File::Path::mkpath($etc);
    return $etc;
}

sub find_repo {
    my $self = shift;
    my $root = rootdir;
    my $try  = cwd;

    until ( $try eq $root ) {
        if ( -d ( my $repo = $try->child('.bif') ) ) {
            $log->debug( 'ctx: repo: ' . $repo );
            $self->{_bif_repo} = $repo;
            last;
        }
        $try = $try->parent;
    }

    return unless $self->{_bif_repo};

    my $file = $self->repo->child('config');
    return unless $file->exists;

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

    return;
}

sub err {
    my $self = shift;
    Carp::croak('err($type, $msg, [$arg])') unless @_ >= 2;
    my $err = shift;
    my $msg = shift;

    require Term::ANSIColor;
    $msg =
        Term::ANSIColor::color('red')
      . 'fatal:'
      . Term::ANSIColor::color('reset') . ' '
      . $msg . "\n";

    die Bif::Error->new( {%$self}, $err, $msg, @_ );
}

sub ok {
    my $self = shift;
    Carp::croak('ok($type, [$arg])') unless @_;
    my $ok = shift;
    return Bif::OK->new( {%$self}, $ok, @_ );
}

sub start_pager {
    my $self  = shift;
    my $lines = shift;
    return if $self->{_bif_no_pager} or exists $self->{_bif_pager};

    if ($lines) {
        require Term::Size;
        return if $lines <= ( ( Term::Size::chars() )[1] );
    }

    local $ENV{'LESS'} = '-FXeR';
    local $ENV{'MORE'} = '-FXer' unless $^O =~ /^MSWin/;

    require IO::Pager;
    my $pager = IO::Pager->new(*STDOUT);
    $log->debug('ctx: start_pager');

    $pager->binmode(':encoding(utf8)') if ref $pager;

    $self->{_bif_pager} = $pager;

    $SIG{__DIE__} = sub {
        return if $^S or !defined $^S;
        $| = 1;
        STDOUT->flush;
        $self->end_pager();
    };
}

sub end_pager {
    my $self = shift;
    return unless $self->{_bif_pager};

    $log->debug('ctx: end_pager');
    $self->{_bif_pager}->close;
    delete $self->{_bif_pager};
    delete $SIG{__DIE__};
    return;
}

sub repo {
    my $self = shift;

    return $self->{_bif_repo}
      || $self->err( 'RepoNotFound', 'directory not found: .bif/' );
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

sub get_project {
    my $self  = shift;
    my $path  = shift;
    my $alias = shift;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;
    my @matches = $db->get_projects( $path, $alias );

    return $self->err( 'AmbiguousPath', "ambiguous path: $path" )
      if @matches > 1;

    return $matches[0];
}

sub render_table {
    my $self   = shift;
    my $format = shift;
    my $header = shift;
    my $data   = shift;
    my $indent = shift || 0;

    require Text::FormatTable;
    require Term::Size;
    require Term::ANSIColor;

    my $table = Text::FormatTable->new($format);

    if ($header) {
        $header->[0] = Term::ANSIColor::color('white') . $header->[0];
        push( @$header, ( pop @$header ) . Term::ANSIColor::color('reset') );
        $table->head(@$header);
        $table->rule( Term::ANSIColor::color('dark')
              . ( $self->{_bif_terminal} ? '–' : '-' )
              . Term::ANSIColor::color('reset') );
    }

    foreach my $row (@$data) {
        $table->row(@$row);
    }

    return $table->render( ( Term::Size::chars() )[0] ) unless $indent;

    my $str = $table->render( ( Term::Size::chars() )[0] - $indent );
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
        txt            => "

# Please enter your message. Lines starting with '#'
# are ignored. Empty content aborts.
#
",
        @_,
    );

    foreach my $key ( sort keys %{ $args{opts} } ) {
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

    if ( $self->{_bif_pager} or $self->{debug} ) {
        return print $msg . "\n";
    }

    local $| = 1;

    my $chars = print ' ' x length($old), "\b" x length($old), $msg, "\r";
    $self->{_bif_print} = $msg =~ m/\n/ ? '' : $msg;
    return $chars;
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

App::bif::Context - A context class for App::bif::* commands

=head1 VERSION

0.1.0_14 (2014-04-24)

=head1 SYNOPSIS

    # In App/bif/command/name.pm
    use strict;
    use warnings;
    use App::bif::Context;

    sub run {
        my $ctx  = App::bif::Context->new(shift);
        my $db   = $ctx->db;
        my $data = $db->xarray(...);

        return $ctx->err( 'SomeFailure', 'something failed' )
          if ($ctx->{command_option});

        $ctx->start_pager;

        print $ctx->render_table(
            ' r  l  l ',
            [qw/ ID Title Status /],
            $data, 
        );

        $ctx->end_pager;

        return $ctx->ok('CommandName');
    }

=head1 DESCRIPTION

B<App::bif::Context> provides a context/configuration object for bif
commands. It is a blessed hashref, and commands are expected to grab
configuration keys and call methods on it.

The above synopsis is the basic template for any bif command. At run
time the C<run> function is called by C<OptArgs::dispatch> with the
options hashref as the first argument. The first thing the bif command
should do it call C<App::bif::Context->new> to set up a bif context
which sets up logging and merges the user and repository configurations
with the command-line options.

The following utility functions are all automatically exported into the
calling package.  B<App::bif::Context> sets the encoding of C<STDOUT>
and C<STDIN> to utf-8 when it is loaded.

=head1 CONSTRUCTOR

=over 4

=item App::bif::Context->new( $ctx ) -> $ctx

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

=item repo -> Path::Tiny

Return the path to the first '.bif' directory found starting from the
current working directory and searching upwards. Raises a
'RepoNotFound' error on failure.

=item db -> Bif::DB::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>). The handle is only good for read operations -
use C<$ctx->dbw> when inserting,updating or deleting from the database.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<bif_db>, in order to keep startup time short for cases
such as when the repository is not found.

=item dbw -> Bif::DBW::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>). The handle is good for INSERT, UPDATE and DELETE
operations.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<$ctx->dbw>, in order to keep startup time short for
cases such as when the repository is not found.

=item get_project( $path, [ $hub ]) -> HashRef

Calls C<get_projects> from C<Bif::DB> and raises an error if more than
one project is found. Otherwise it passes back the the single hashref
returned.

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

