package App::bif::Util;
use strict;
use warnings;
use utf8;    # for render_table
use Carp ();
use Exporter::Tidy default => [
    qw/
      bif_err
      bif_ok
      bif_init
      bif_repo
      bif_conf
      bif_user_conf
      bif_db
      bif_dbw
      start_pager
      end_pager
      render_table
      prompt_edit
      /
  ],
  other => [
    qw/
      /
  ];
use Log::Any qw/$log/;
use Path::Tiny qw/path rootdir cwd/;

our $VERSION = '0.1.0';

binmode STDIN,  ':encoding(utf8)';
binmode STDOUT, ':encoding(utf8)';

sub bif_err {
    require Term::ANSIColor;
    my $error = shift;
    my $msg =
        Term::ANSIColor::color('red')
      . 'fatal:'
      . Term::ANSIColor::color('reset') . ' '
      . shift . "\n";

    die Bif::Error->new( $error, $msg ) unless @_;
    die Bif::Error->new( $error, sprintf( $msg, @_ ) );
}

sub bif_ok {
    my $type = shift || Carp::croak('usage: bif_ok($type, [$arg])');
    my $arg = shift;
    return Bif::OK->new( $type, $arg );
}

my $NO_PAGER = 1;
my $pager;

sub start_pager {
    return if $NO_PAGER or $pager;

    if ( my $lines = shift ) {
        require Term::Size;
        return if $lines <= ( ( Term::Size::chars() )[1] );
    }

    local $ENV{'LESS'} = '-FXeR';
    local $ENV{'MORE'} = '-FXer' unless $^O =~ /^MSWin/;

    require IO::Pager;
    $pager = IO::Pager->new(*STDOUT);

    $pager->binmode(':encoding(utf8)') if ref $pager;

    $SIG{__DIE__} = sub {
        return if $^S or !defined $^S;
        $| = 1;
        STDOUT->flush;
        end_pager();
    };
}

sub end_pager {
    return unless $pager;

    $pager->close;
    undef $pager;
    delete $SIG{__DIE__};
    return;
}

our $STDOUT_TERMINAL;
my $opts;

sub bif_init {
    $opts = shift || Carp::croak('usage: bif_init($opts)');

    $STDOUT_TERMINAL = -t STDOUT;
    $NO_PAGER = !$STDOUT_TERMINAL || delete $opts->{no_pager};

    # This affect Term::ANSIColor
    $ENV{ANSI_COLORS_DISABLED} = 1 unless $STDOUT_TERMINAL;

    start_pager() if $opts->{debug};

    if ( $opts->{debug} ) {
        require Log::Any::Adapter;
        Log::Any::Adapter->set('Stdout');
    }

    $log->debugf( 'bif_init: %s %s', (caller)[0], $opts );

    return $opts;
}

sub bif_repo {
    my $root = rootdir;
    my $try  = cwd;

    until ( $try eq $root ) {
        if ( -d ( my $repo = $try->child('.bif') ) ) {
            $log->debug( 'bif_repo: ' . $repo );
            return $repo;
        }
        $try = $try->parent;
    }

    bif_err( 'RepoNotFound',
        'no current repository (directory ".bif/" not found)' );
}

sub bif_user_conf {
    require Config::Tiny;
    require File::HomeDir;

    my $config_dir =
      File::HomeDir->my_dist_config( 'App-bif', { create => 1 } );

    my $userfile = path( $config_dir, 'config' );

    if ( -e $userfile ) {
        return Config::Tiny->read($userfile)
          || confess $Config::Tiny::errstr;
    }

    $log->debug( 'bif_user_conf: ' . $userfile );

    require IO::Prompt::Tiny;
    print "Initial Setup, please provide the following details:\n";

    my $conf = Config::Tiny->new;
    $conf->{user}->{name}  = IO::Prompt::Tiny::prompt( 'Name:',  'Example' );
    $conf->{user}->{email} = IO::Prompt::Tiny::prompt( 'Email:', 'ex@amp.le' );

    print "Writing $userfile\n";
    $conf->write($userfile);

    return $conf;
}

sub bif_conf {
    my $repo     = bif_repo;
    my $userconf = bif_user_conf;
    my $file     = $repo->child('config');

    $log->debug( 'bif_conf: ' . $file );

    my $conf = Config::Tiny->read( $file, 'utf8' )
      || bif_err( 'ConfigNotFound', $file . ' ' . Config::Tiny->errstr );

    foreach my $toplevel ( keys %$userconf ) {
        $conf->{$toplevel}->{$_} ||= $userconf->{$toplevel}->{$_}
          for keys %{ $userconf->{$toplevel} };
    }

    return $conf;
}

sub bif_db {
    my $path = shift;
    my $repo = $path ? path($path) : bif_repo;
    my $dsn  = 'dbi:SQLite:dbname=' . $repo->child('db.sqlite3');

    $log->debug( 'bif_db: ' . $dsn );

    require Bif::DB;
    my $db = Bif::DB->connect($dsn);
    $db->sqlite_trace( sub { $log->debug(@_) } ) if $opts->{debug};
    return $db;
}

sub bif_dbw {
    my $path = shift;
    my $repo = $path ? path($path) : bif_repo;
    my $dsn  = 'dbi:SQLite:dbname=' . $repo->child('db.sqlite3');

    #    $dsn = 'dbi:SQLite:dbname=:memory:';

    $log->debug( 'bif_dbw: ' . $dsn );

    require Bif::DB::RW;
    my $db = Bif::DB::RW->connect($dsn);
    $db->sqlite_trace( sub { $log->debug(@_) } ) if $opts->{debug};
    return $db;
}

sub render_table {
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
              . ( $STDOUT_TERMINAL ? '–' : '-' )
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
        bif_err( 'EmptyContent', 'aborting due to empty content.' )
          if $args{val} =~ m/^[\s\n]*$/s;
    }

    return $args{val};
}

package Bif::OK;
use overload
  bool     => sub { 1 },
  '""'     => \&as_string,
  fallback => 1;

sub new {
    my $proto = shift;
    my $type  = shift || Carp::croak('missing type');
    my $ref   = shift;

    $proto = ref $proto if ref $proto;
    my $class = $proto . '::' . $type;

    {
        no strict 'refs';
        *{ $class . '::ISA' } = [$proto];
    }

    if ( !defined $ref ) {
        return bless \$class, $class;
    }
    elsif ( ref $ref ) {
        return bless $ref, $class;
    }
    else {
        return bless \$ref, $class;
    }
}

sub as_string {
    my $ref = shift;
    return $$ref if $ref->isa('SCALAR');
    return ref $ref;
}

package Bif::Error;
our @ISA = ('Bif::OK');

1;

__END__

=head1 NAME

App::bif::Util - Utility functions for App::bif::* scripts

=head1 VERSION

0.1.0 (yyyy-mm-dd)

=head1 SYNOPSIS

    # In App/bif/command/name.pm
    use strict;
    use warnings;
    use App::bif::Util;

    sub run {
        my $opts = bif_init(shift);
        my $db   = bif_db;
        my $data = $db->xarray(...);

        bif_err('SomeFailure', 'something failed')
          if ($some_failure);

        start_pager;

        print render_table(
            ' r  l  l ',
            [ qw/ ID Title Status / ],
            $data,
        );

        stop_pager;

        return bif_ok('CommandName');
    }

=head1 DESCRIPTION

The above synopsis is the basic template for any bif command. At run
time the C<run> function is called by C<OptArgs::dispatch> with the
options hashref as the first argument. The first thing the bif command
should do it call C<bif_init> to set up logging. Everything after that
is a matter of reading or writing to the terminal and/or the database.

The following utility functions are all automatically exported into the
calling package.  B<App::bif::Util> sets the encoding of C<STDOUT> and
C<STDIN> to utf-8 when it is loaded.

=over 4

=item bif_err( $err, $message, [ @args ])

Throws an exception that stringifies to C<$message> prefixed with
"fatal: ". The exception is an object from the C<Bif::Error::$err>
class which is used by test scripts to reliably detect the type of
error. If C<@args> exists then C<$message> is assumed to be a format
string to be converted with L<sprintf>.

=item bif_ok( $type, [ $arg ])

Returns a C<Bif::OK::$type> object, either as a reference to C<$arg> or
as a reference to the class name. Every App::Bif::* command should
return such an object, which can be tested for by tests.

=item start_pager([ $rows ])

Start a pager (less, more, etc) on STDOUT using L<IO::Pager>, provided
that C<--no-pager> has not been used. The pager handle encoding is set
to utf-8. If the optional C<$rows> has been given then the pager will
only be started if L<Term::Size> reports the height of the terminal as
being less than C<$rows>.

=item end_pager

Stops the pager on STDOUT if it was previously started.

=item bif_init( $opts ) -> $opts

Initializes the common elements of all bif scripts. Requires the
options hashref as provided by L<OptArgs> but also returns it.

=over

=item * Sets the package variable C<$App::bif::Util::STDOUT_TERMINAL> to
true if C<STDOUT> is connected to a terminal.

=item * Sets the environment variable C<ANSI_COLORS_DISABLED> to
1 if C<STDOUT> is I<not> connected to a terminal, in order to disable
L<Term::ANSIColor> functions.

=item * Starts a pager if C<--debug> is true, unless C<--no-pager> is
also set to true or C<STDOUT> is not connected to a terminal.

=item * Adds unfiltered logging via L<Log::Any::Adapter::Stdout>.

=back

=item bif_repo -> Path::Tiny

Return the path to the first '.bif' directory found starting from the
current working directory and searching upwards. Raises a
'RepoNotFound' error on failure.

=item bif_user_conf -> HashRef

Returns the user configuration. Will prompt for values and construct
the file if it doesn't exist first.

=item bif_conf -> HashRef

Returns the configuration for the current repository, a merge of the
user configuration file and the repository configuration file.

=item bif_db( [$directory] ) -> Bif::DB::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>) or in the repository given as C<$directory>. The
handle is only good for read operations - use C<bif_dbw> when
inserting,updating or deleting from the database.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<bif_db>, in order to keep startup time short for cases
such as when the repository is not found.

=item bif_dbw( [$directory] ) -> Bif::DB::RW::db

Returns a handle for the SQLite database in the current respository (as
found by C<bif_repo>) or in the repository given as C<$directory>. The
handle is good for INSERT, UPDATE and DELETE operations.

You should manually import any L<DBIx::ThinSQL> functions you need only
after calling C<bif_dbw>, in order to keep startup time short for cases
such as when the repository is not found.

=item render_table( $format, \@header, \@data, [ $indent ] ) -> Str

Uses L<Text::FormatTable> to construct a table of <@data>, aligned and
spaced according to C<$format>, preceded by a C<@header>. If C<$indent>
is greater than zero then the entire table is indented by that number
of spaces.

=item prompt_edit( %options ) -> Str

If the environment is interactive this function will invoke an editor
and return the result. All comment lines (beginning with '#') are
removed. TODO: describe %options.

=back

=head1 SEE ALSO

L<Bif::DB>, L<Bif::DB::RW>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

