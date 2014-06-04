package App::bif::Context;
use strict;
use warnings;
use utf8;    # for render_table
use Carp ();
use Config::Tiny;
use File::HomeDir;
use Log::Any qw/$log/;
use Path::Tiny qw/path rootdir cwd/;
use Term::Size ();
use feature 'state';

our $VERSION = '0.1.0_23';

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

    $self->{_bif_terminal} = -t STDOUT;
    $self->{_bif_no_pager} = !$self->{_bif_terminal} || $opts->{no_pager};

    # For Term::ANSIColor
    $ENV{ANSI_COLORS_DISABLED} = !$self->{_bif_terminal} || $opts->{no_color};

    if ( $opts->{debug} ) {
        require Log::Any::Adapter;
        $self->{_bif_log_any_adapter} = Log::Any::Adapter->set('Stdout');
        $self->start_pager();
    }

    $log->debugf( 'ctx: %s %s', (caller)[0], $opts );
    $log->debugf( 'ctx: terminal %dx%d', $term_width, $term_height );

    $self->load_user_conf;
    $self->find_repo;

    # Merge in the command line options with the (user/repo) config
    $self->{$_} = $opts->{$_} for keys %$opts;
    return $self;
}

sub create_user_conf {
    my $self     = shift;
    my $home_dir = File::HomeDir->my_home;
    my $data_dir = File::HomeDir->my_data;

    my $conf_dir =
      $home_dir eq $data_dir
      ? path( $home_dir, '.bif-user' )
      : path( $data_dir, 'bif-user' );

    $conf_dir->mkpath unless -d $conf_dir;
    my $file = path( $conf_dir, 'config' );

    return $file if -e $file;

    require IO::Prompt::Tiny;
    $log->debug( 'ctx: creating user_conf: ' . $file );

    print "Initial Setup, please provide the following details:\n";

    my $git_conf_file = path( File::HomeDir->my_home, '.gitconfig' );
    my $git_conf = Config::Tiny->read($git_conf_file) || {};

    my $name  = $git_conf->{user}->{name}  || 'Your Name';
    my $email = $git_conf->{user}->{email} || 'your@email.adddr';

    $name =~ s/(^")|("$)//g;
    $email =~ s/(^")|("$)//g;

    my $conf = Config::Tiny->new;
    $conf->{user}->{name}  = IO::Prompt::Tiny::prompt( 'Name:',  $name );
    $conf->{user}->{email} = IO::Prompt::Tiny::prompt( 'Email:', $email );
    $conf->{'user.alias'}->{l} = 'list projects local --status run';
    $conf->{'user.alias'}->{ls} =
      'list topics --status open --project-status run';

    print "Writing $file\n";
    $conf->write($file);

    $self->{$_} ||= $conf->{$_} for keys %$conf;

    return $file;
}

sub load_user_conf {
    my $self = shift;
    my $file = $self->create_user_conf;

    my $conf = Config::Tiny->read($file)
      || confess $Config::Tiny::errstr;

    $log->debug( 'ctx: user_conf: ' . $file );

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

    # Used by t/App/bif/Context.t
    $self->{_bif_user_config} = $file;
    return;
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

sub uuid2id {
    my $self = shift;
    my $try  = shift;

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
    my $hub  = shift;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;
    my @matches = $db->get_projects( $path, $hub );

    if ( !@matches ) {
        if ($hub) {
            return $self->err( 'HubNotFound', "hub not found: $hub" )
              unless scalar $db->get_hub_repos($hub);

            return $self->err( 'ProjectNotFound',
                "project not found: $path ($hub)" );
        }
        return $self->err( 'ProjectNotFound', "project not found: $path" );
    }
    elsif ( @matches > 1 ) {
        return $self->err( 'AmbiguousPath', "ambiguous path: $path" );
    }

    return $matches[0];
}

sub render_table {
    my $self   = shift;
    my $format = shift;
    my $header = shift;
    my $data   = shift;
    my $indent = shift || 0;

    require Text::FormatTable;
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

    if ( $pager or $self->{debug} ) {
        return print $msg . "\n";
    }

    local $| = 1;

    my $chars = print ' ' x length($old), "\b" x length($old), $msg, "\r";
    $self->{_bif_print} = $msg =~ m/\n/ ? '' : $msg;
    return $chars;
}

sub get_topic {
    my $self = shift;
    my $token = shift // return;

    my $db = $self->{_bif_dbw} || $self->{_bif_db} || $self->db;

    state $have_qv = DBIx::ThinSQL->import(qw/ qv bv /);

    if ( $token =~ m/^\d+$/ ) {
        my $data = $db->xhash(
            select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'topics.first_update_id',
                qv(undef)->as('project_issue_id'),
                qv(undef)->as('project_id'),
            ],
            from  => 'topics',
            where => [
                'topics.id = ',         bv($token),
                ' AND topics.kind != ', qv('issue')
            ],
            union_all_select => [
                'topics.id',
                'topics.kind',
                'topics.uuid',
                'topics.first_update_id',
                'project_issues.id AS project_issue_id',
                'project_issues.project_id',
            ],
            from       => 'project_issues',
            inner_join => 'topics',
            on         => 'topics.id = project_issues.issue_id',
            where      => { 'project_issues.id' => $token },
        );

        return $data if $data;
    }

    my $pinfo = eval { $self->get_project($token) };
    return $pinfo if $pinfo;

    return $self->err( 'TopicNotFound',
        'topic, update or path not found: ' . $token );
}

sub update_repo {
    my $self = shift;
    my $ref  = shift;
    my $dbw  = $self->{_bif_dbw} || $self->db;

    $ref->{author} ||= $self->{user}->{name};
    $ref->{email}  ||= $self->{user}->{email};
    $ref->{id}     ||= $dbw->nextval('updates');
    my $hub = $self->get_topic( $dbw->get_local_hub_id );

    $dbw->xdo(
        insert_into => 'updates',
        values      => {
            id        => $ref->{id},
            parent_id => $hub->{first_update_id},
            author    => $ref->{author},
            email     => $ref->{email},
            message   => $ref->{message},
        },
    );

    # TODO related_update_uuid is useless because we now do the
    # update_repo generally before the actual update and uuid isn't
    # calculated. Get rid of it.

    state $have_qv = DBIx::ThinSQL->import(qw/ qv /);
    $dbw->xdo(
        insert_into =>
          [ 'hub_deltas', qw/hub_id update_id project_id related_update_uuid/ ],
        select => [
            qv( $hub->{id} ),
            qv( $ref->{id} ),
            qv( $ref->{project_id} ),
            'u.uuid',
        ],
        from      => '(select 1)',
        left_join => 'updates u',
        on        => {
            'u.id' => $ref->{related_update_id},
        },
    );

    # TODO this will update other updates which we may not wish to
    # happen... remove?
    $dbw->xdo(
        insert_into => 'func_merge_updates',
        values      => { merge => 1 },
    );

    return;
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

App::bif::Context - A context class for App::bif::* commands

=head1 VERSION

0.1.0_23 (2014-06-04)

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

=item uuid2id( $try ) -> Int

Returns C<$try> unless a C<< $ctx->{uuid} >> option has been set.
Returns C<< Bif::DB->uuid2id($try) >> if the lookup succeeds or else
raises an error.

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

=item get_topic( $TOKEN ) -> HashRef

Looks up the topic identified by C<$TOKEN> and returns undef or a hash
reference containg the following keys:

=over

=item * id - the topic ID

=item * first_update_id - the update_id that created the topic

=item * kind - the type of the topic

=item * uuid - the universally unique identifier of the topic

=back

If the found topic is an issue then the following keys will also
contain valid values:

=over

=item * project_issue_id - the project-specific topic ID

=item * project_id - the project ID matching the project_issue_id

=back


=item update_repo($hashref)

Create an update of the local repo from a hashref containing a ruid (an
update_id), user name, a user email, and a message. C<$hashref> can
optionally contain an update_id which will be converted into a uuid,
used for uniqueness in the event that multiple calls to update_repo
with the same values occur in the same second.

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

