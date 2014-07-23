package App::bif::init;
use strict;
use warnings;
use AnyEvent;
use App::bif::Context;
use Bif::Client;
use Bif::DBW;
use Config::Tiny;
use Coro;
use DBIx::ThinSQL qw/bv qv/;
use Log::Any '$log';
use Path::Tiny qw/path cwd tempdir/;

our $VERSION = '0.1.0_26';

my $stderr;
my $stderr_watcher;

sub cleanup_errors {
    my $hub = shift;

    undef $stderr_watcher;
    $stderr->blocking(0);

    while ( my $line = $stderr->getline ) {
        print STDERR "$hub: $line";
    }

    return;
}

sub init_user {
    my $ctx      = shift;
    my $home_dir = File::HomeDir->my_home;
    my $data_dir = File::HomeDir->my_data;

    my $user_repo =
      $home_dir eq $data_dir
      ? path( $home_dir, '.bif-user' )->absolute
      : path( $data_dir, 'bif-user' )->absolute;

    return if -e $user_repo;

    $user_repo->parent->mkpath;

    my $tempdir =
      tempdir( DIR => $user_repo->parent, CLEANUP => !$ctx->{debug} );
    $log->debug( 'init user_db: tmpdir ' . $tempdir );

    my $git_conf_file = path( File::HomeDir->my_home, '.gitconfig' );
    my $git_conf = Config::Tiny->read($git_conf_file) || {};

    my $name  = $git_conf->{user}->{name}  || 'Your Name';
    my $email = $git_conf->{user}->{email} || 'your@email.adddr';

    $name =~ s/(^")|("$)//g;
    $email =~ s/(^")|("$)//g;

    require IO::Prompt::Tiny;
    print "Initialising your bif identity:\n";
    $name  = IO::Prompt::Tiny::prompt( 'Name:',  $name );
    $email = IO::Prompt::Tiny::prompt( 'Email:', $email );

    my $conf = Config::Tiny->new;
    $conf->{'user.alias'}->{ls} =
      'list topics --status open --project-status run';
    $conf->{'user.alias'}->{lss} =
      'list topics --status stalled --project-status run';
    $conf->{'user.alias'}->{lsp} = 'list projects define plan run';
    $conf->{'user.alias'}->{lsi} = 'list identities';

    my $file = $tempdir->child('config');
    $conf->write($file);

    my $dbfile = $tempdir->child('db.sqlite3');
    my $dbw    = Bif::DBW->connect( 'dbi:SQLite:dbname=' . $dbfile,
        undef, undef, undef, $ctx->{debug} );

    my ( $old, $new );
    $dbw->txn(
        sub {
            ( $old, $new ) = $dbw->deploy;

            my $iid   = $dbw->nextval('topics');
            my $ecmid = $dbw->nextval('topics');
            my $hid   = $dbw->nextval('topics');
            my $rid   = $dbw->nextval('topics');
            my $uid   = $dbw->nextval('updates');

            $dbw->xdo(
                insert_into => 'updates',
                values      => {
                    id          => $uid,
                    identity_id => $iid,
                    author      => $name,
                    email       => $email,
                    message     => 'Automatic User Identity Creation',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    update_id => $uid,
                    id        => $iid,
                    kind      => 'identity',
                    name      => $name,
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    entity_id => $iid,
                    method    => 'email',
                    mvalue    => bv( $email, DBI::SQL_VARCHAR ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    update_id                 => $uid,
                    id                        => $iid,
                    contact_id                => $iid,
                    default_contact_method_id => $ecmid,
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_identity',
                values      => {
                    update_id => $uid,
                    id        => $iid,
                    self      => 1,
                },
            );

            $uid = $dbw->nextval('updates');

            $dbw->xdo(
                insert_into => 'updates',
                values      => {
                    id          => $uid,
                    identity_id => $iid,
                    author      => $name,
                    email       => $email,
                    message     => 'user init'
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_hub',
                values      => {
                    id        => $hid,
                    update_id => $uid,
                    local     => 1,
                    name => 'localhub-' . sprintf( "%08x", rand(0xFFFFFFFF) ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_hub_repo',
                values      => {
                    id        => $rid,
                    hub_id    => $hid,
                    update_id => $uid,
                    location  => $user_repo,
                },
            );

            $dbw->xdo(
                update => 'hubs',
                set    => { default_repo_id => $rid },
                where  => { id => $hid },
            );

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    symlink( '.', $tempdir->child('.bif') );
    rename( $tempdir, $user_repo )
      || return $ctx->err( 'Rename', "rename $tempdir $user_repo: $!" );

    printf "Identity initialised (v%s) in %s/\n", $new, $user_repo;

    return $ctx->ok('Init');
}

sub run {
    my $opts = shift;
    $opts->{no_pager}++;    # causes problems with something in Coro?

    my $ctx = App::bif::Context->new( {%$opts} );
    init_user($ctx);

    # Reset the context because the user repo may have just been newly
    # created.
    $ctx = App::bif::Context->new( {%$opts} );

    my $user_db = $ctx->user_db;

    $ctx->{directory} = path( $ctx->{directory} || cwd )->absolute;

    my $bifdir;
    my $name;
    if ( $ctx->{bare} ) {
        $bifdir = $ctx->{directory};
        $name   = $ctx->{directory}->basename;
    }
    else {
        $bifdir = $ctx->{directory}->child('.bif');
        $name = 'localhub-' . sprintf( "%08x", rand(0xFFFFFFFF) ),;
    }

    return $ctx->err( 'DirExists', 'directory exists: ' . $bifdir )
      if -e $bifdir;

    $bifdir->parent->mkpath;

    my $tempdir = tempdir( DIR => $bifdir->parent, CLEANUP => !$ctx->{debug} );
    $log->debug( 'init: tmpdir ' . $tempdir );

    my $dbfile = $tempdir->child('db.sqlite3');
    my $dbw    = Bif::DBW->connect( 'dbi:SQLite:dbname=' . $dbfile,
        undef, undef, undef, $ctx->{debug} );

    $log->debug( 'init: SQLite version: ' . $dbw->{sqlite_version} );

    $|++;    # no buffering

    my $error;
    my $cv = AE::cv;

    my $client = Bif::Client->new(
        db            => $dbw,
        location      => $ctx->user_repo,
        debug         => $ctx->{debug},
        debug_bifsync => $ctx->{debug_bifsync},
        on_error      => sub {
            $error = shift;
            $cv->send;
        },
    );

    $stderr = $client->child->stderr;

    $stderr_watcher = AE::io $stderr, 0, sub {
        my $line = $stderr->getline;
        if ( !defined $line ) {
            undef $stderr_watcher;
            return;
        }
        print STDERR "user_db: $line";
    };

    my ( $old, $new );
    my $coro = async {
        eval {
            $dbw->txn(
                sub {
                    ( $old, $new ) = $dbw->deploy;

                    my $status = $client->bootstrap_identity;

                    unless ( $status eq 'IdentityImported' ) {
                        $dbw->rollback;
                        $error = "unexpected status received: $status";
                        return cleanup_errors('user_db');

                    }

                    my $uid = $dbw->nextval('updates');
                    my $hid = $dbw->nextval('topics');
                    my $rid = $dbw->nextval('topics');

                    $dbw->xdo(
                        insert_into =>
                          [ 'updates', qw/id identity_id message/ ],
                        select => [ qv($uid), 'ids.id', qv('init') ],
                        from   => 'identity_self ids',
                    );

                    $dbw->xdo(
                        insert_into => 'func_new_hub',
                        values      => {
                            id        => $hid,
                            update_id => $uid,
                            local     => 1,
                            name      => $name,
                        },
                    );

                    $dbw->xdo(
                        insert_into => 'func_new_hub_repo',
                        values      => {
                            id        => $rid,
                            hub_id    => $hid,
                            update_id => $uid,
                            location  => $bifdir,
                        },
                    );

                    $dbw->xdo(
                        update => 'hubs',
                        set    => { default_repo_id => $rid },
                        where  => { id => $hid },
                    );

                    #                    $dbw->xdo(
                    #                        update => 'entities',
                    #                        set    => { hub_id => $hid },
                    #                        where  => { id => $iid },
                    #                    );

                    $dbw->xdo(
                        insert_into => 'func_merge_updates',
                        values      => { merge => 1 },
                    );

                    return cleanup_errors;
                }
            );
        };

        if ($@) {
            $error .= $@;
        }

        $client->disconnect;
        return $cv->send( !$error );
    };

    return $ctx->err( 'Unknown', $error ) unless $cv->recv;

    symlink( '.', $tempdir->child('.bif') ) if $ctx->{bare};

    rename( $tempdir, $bifdir )
      || return $ctx->err( 'Rename', "rename $tempdir $bifdir: $!" );

    printf "Repository initialised (v%s) in %s/\n", $new, $bifdir;

    return $ctx->ok('Init');

    $dbw->txn(
        sub {
            my ( $old, $new ) = $dbw->deploy;
            printf "Database initialised (v%s)/\n", $new;

            my $iid   = $dbw->nextval('topics');
            my $ecmid = $dbw->nextval('topics');
            my $hid   = $dbw->nextval('topics');
            my $rid   = $dbw->nextval('topics');
            my $uid   = $dbw->nextval('updates');

            # Bootstrap the user identity so we can perform other
            # actions using bif commands

            $dbw->xdo(
                insert_into => 'updates',
                values      => $user_db->xhash(
                    select => [
                        qv($uid)->as('id'), qv($iid)->as('identity_id'),
                        'u.author',         'u.email',
                        'u.lang',           'u.message',
                        'u.mtime',          'u.mtimetz',
                        'u.uuid',
                    ],
                    from       => 'identity_self ids',
                    inner_join => 'topics t',
                    on         => 't.id = ids.id',
                    inner_join => 'updates u',
                    on         => 'u.id = t.first_update_id',
                ),
            );

            $dbw->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    update_id => $uid,
                    id        => $iid,
                    kind      => 'identity',
                    name      => $ctx->{user}->{name},
                },
                values => $user_db->xhash(
                    select => [
                        qv($uid)->as('update_id'),  qv($iid)->as('id'),
                        qv('identity')->as('kind'), 'e.name',
                    ],
                    from       => 'identity_self ids',
                    inner_join => 'entity_deltas ed',
                    on         => 'ed.entity_id = ids.id',
                    order_by   => 'ed.id ASC',
                    limit      => 1,
                ),
            );

            $dbw->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    entity_id => $iid,
                    method    => 'email',
                    mvalue    => bv( $ctx->{user}->{email}, DBI::SQL_VARCHAR ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    update_id                 => $uid,
                    id                        => $iid,
                    contact_id                => $iid,
                    default_contact_method_id => $ecmid,
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_identity',
                values      => {
                    update_id => $uid,
                    id        => $iid,
                    self      => 1,
                },
            );

            $uid = $dbw->nextval('updates');

            $dbw->xdo(
                insert_into => 'updates',
                values      => {
                    id          => $uid,
                    identity_id => $iid,
                    author      => $ctx->{user}->{name},
                    email       => $ctx->{user}->{email},
                    message     => 'init '
                      . $ctx->{directory}
                      . ( $ctx->{bare} ? ' --bare' : '' ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_hub',
                values      => {
                    id        => $hid,
                    update_id => $uid,
                    local     => 1,
                    name      => $name,
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_hub_repo',
                values      => {
                    id        => $rid,
                    hub_id    => $hid,
                    update_id => $uid,
                    location  => $bifdir,
                },
            );

            $dbw->xdo(
                update => 'hubs',
                set    => { default_repo_id => $rid },
                where  => { id => $hid },
            );

            $dbw->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );
        }
    );

    symlink( '.', $tempdir->child('.bif') ) if $ctx->{bare};

    rename( $tempdir, $bifdir )
      || return $ctx->err( 'Rename', "rename $tempdir $bifdir: $!" );

    printf "Database initialised (v%s) in %s/\n", $new, $bifdir;

    return $ctx->ok('Init');
}

1;
__END__

=head1 NAME

bif-init -  create new bif repository

=head1 VERSION

0.1.0_26 (2014-07-23)

=head1 SYNOPSIS

    bif init [DIRECTORY] [OPTIONS...]

=head1 DESCRIPTION

The C<bif init> command initialises a new bif repository. The
repository is usually a directory named F<.bif> containing the
following files:

=over

=item F<config>:

Configuration information in INI format

=item F<db.sqlite3>:

repository data in an SQLite database

=back

By default F<.bif> is created underneath the current working directory.

    bif init

You can initialise a repository under a different location by giving a
DIRECTORY as the first argument, which will be created if it doesn't
already exist.

    bif init elsewhere

If you are creating a repository for use as a hub then the C<--bare>
option can be used to skip the creation of the F<.bif> directory.

    bif init my-hub --bare

Attempting to initialise an existing repository is considered an error.

=head1 ARGUMENTS & OPTIONS

=over

=item DIRECTORY

The parent location of the respository directory. Defaults to the
current working directory (F<.> or F<$PWD>).

=item --bare

Initialize the repository in F<DIRECTORY> directly instead of
F<DIRECTORY/.bif>.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.


