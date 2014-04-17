package Bif::DB::RW;
use strict;
use warnings;
use Bif::DB;
use DBIx::ThinSQL qw//;
use DBIx::ThinSQL::SQLite ':all';
use Log::Any '$log';

our $VERSION = '0.1.0_10';
our @ISA     = ('Bif::DB');

create_methods(qw/nextval currval/);

sub _connected {
    my $dbh   = shift;
    my $debug = shift;

    $dbh->sqlite_trace( sub { $log->debug(@_) } ) if $debug;

    $dbh->do('PRAGMA foreign_keys = ON;');
    $dbh->do('PRAGMA temp_store = MEMORY;');
    $dbh->do('PRAGMA recursive_triggers = ON;');
    $dbh->do('PRAGMA synchronous = NORMAL;');
    $dbh->do('PRAGMA synchronous = OFF;') if $main::BIF_DB_NOSYNC;

    # TODO remove this before the first production release.
    $dbh->do('PRAGMA reverse_unordered_selects = ON;');

    create_functions( $dbh,
        qw/debug create_sequence nextval currval sha1_hex agg_sha1_hex/ );
    return;
}

sub connect {
    my $class = shift;
    my $dsn   = shift;
    my ( $user, $password, $attrs, $debug ) = @_;

    $attrs ||= {
        RaiseError                 => 1,
        PrintError                 => 0,
        ShowErrorStatement         => 1,
        sqlite_see_if_its_a_number => 1,
        sqlite_unicode             => 1,
        Callbacks                  => {
            connected => sub { _connected( shift, $debug ) }
        },
    };

    return $class->SUPER::connect( $dsn, $user, $password, $attrs );
}

package Bif::DB::RW::db;
our @ISA = ('Bif::DB::db');

use DBIx::ThinSQL qw/qv/;

sub deploy {
    my $db = shift;

    require DBIx::ThinSQL::Deploy;

    $db->txn(
        sub {
            if ( defined &static::find ) {
                my $src =
                  'auto/share/dist/App-bif/' . $db->{Driver}->{Name} . '.sql';

                my $sql = static::find($src)
                  or die 'unsupported database type: ' . $db->{Driver}->{Name};

                return $db->deploy_sql($sql);
            }
            else {
                require File::ShareDir;
                require Path::Tiny;

                my $share_dir = $main::BIF_SHARE_DIR
                  || File::ShareDir::dist_dir('App-bif');

                my $deploy_dir =
                  Path::Tiny::path( $share_dir, $db->{Driver}->{Name} );

                if ( !-d $deploy_dir ) {
                    die 'unsupported database type: ' . $db->{Driver}->{Name};
                }

                DBIx::ThinSQL::SQLite::create_sqlite_sequence($db);
                return $db->deploy_dir($deploy_dir);
            }
        }
    );
}

sub update_repo {
    my $dbw = shift;
    my $ref = shift;

    my $repo = $dbw->get_topic( $dbw->get_local_repo_id );
    my $uid  = $dbw->nextval('updates');

    $dbw->xdo(
        insert_into => 'updates',
        values      => {
            id        => $uid,
            parent_id => $repo->{first_update_id},
            author    => $ref->{author},
            email     => $ref->{email},
            message   => $ref->{message},
        },
    );

    $dbw->xdo(
        insert_into =>
          [ 'repo_updates', qw/repo_id update_id related_update_uuid/ ],
        select    => [ qv( $repo->{id} ), qv($uid), 'ru.uuid', ],
        from      => '(select 1)',
        left_join => 'topics ru',
        on        => {
            'ru.id' => $ref->{related_update_id},
        },
    );

    $dbw->xdo(
        insert_into => 'func_merge_updates',
        values      => { merge => 1 },
    );

    return;
}

package Bif::DB::RW::st;
our @ISA = ('Bif::DB::st');

1;

=head1 NAME

Bif::DB::RW - read-write helper methods for a bif database

=head1 VERSION

0.1.0_10 (2014-04-17)

=head1 SYNOPSIS

    use strict;
    use warnings;
    use Bif::DB::RW;

    # Bif inherits from DBIx::ThinSQL, which inherits from DBI.
    my $dbw = Bif::DB::RW->connect( $dsn );

    # Read and write operations on a bif database:

    $dbw->txn(sub {
        my ($old,$new) = $dbw->deploy;

        $dbw->xdo(
            insert_into => 'updates',
            values      => $hashref,
        );

        $dbw->update_repo(
            {
                name  => $name,
                email => $email,
                message   => $message
            }
        );
    });

=head1 DESCRIPTION

B<Bif::DB::RW> is a L<DBI> derivative that provides various read-write
methods for retrieving information from a L<bif> repository. For a
read-only equivalent see L<Bif::DB>. The read-only and read-write parts
are separated for performance reasons.

=head1 DBH METHODS

=over

=item nextval( $name ) -> Int

Advance the sequence C<$name> to its next value and return that value.

=item currval( $name ) -> Int

Return the current value of the sequence <$name>.

=item deploy -> (Int, Int)

Deploys the current Bif distribution schema to the database, returning
the previous (possibly 0) and newly deployed versions.

=item update_repo($hashref)

Create an update of the local repo from a hashref containing a user
name, a user email, and a message.

=back

=head1 SEE ALSO

L<Bif::DB>, L<DBIx::ThinSQL::Deploy>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

