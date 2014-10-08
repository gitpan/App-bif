package App::bif::new::identity;
use strict;
use warnings;
use Bif::Mo;
use Config::Tiny;
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;
use Path::Tiny qw/path/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self   = shift;
    my $opts   = $self->opts;
    my $dbw    = $self->dbw;
    my $name   = '';
    my $email  = '';
    my $spacer = '';

    if ( $opts->{self} ) {
        print "Creating \"self\" identity:\n";

        my $git_conf_file = path( File::HomeDir->my_home, '.gitconfig' );
        my $git_conf = Config::Tiny->read($git_conf_file) || {};

        $name  = $git_conf->{user}->{name}  || 'Your Name';
        $email = $git_conf->{user}->{email} || 'your@email.adddr';

        $name =~ s/(^")|("$)//g;
        $email =~ s/(^")|("$)//g;

        $spacer = '  ';
    }

    $opts->{name} ||= prompt( $spacer . 'Name:', $name )
      || return $self->err( 'NameRequired', 'name is required' );

    my $short = join( '', $opts->{name} =~ m/(\b\w)/g );
    $opts->{shortname} ||= prompt( $spacer . 'Short Name:', $short )
      || return $self->err( 'NameRequired', 'shortname is required' );

    $opts->{method} ||= prompt( $spacer . 'Contact Method:', 'email' )
      || return $self->err( 'MethodRequired', 'method is required' );

    $opts->{value} ||=
      prompt( $spacer . 'Contact ' . ucfirst( $opts->{method} ) . ':', $email )
      || return $self->err( 'ValueRequired', 'value is required' );

    $opts->{message} ||= "New identity for $opts->{name}";

    $dbw->txn(
        sub {
            my $id    = $dbw->nextval('topics');
            my $ecmid = $dbw->nextval('topics');
            my $uid;

            if ( $opts->{self} ) {
                $uid = $dbw->nextval('changes');
                $dbw->xdo(
                    insert_into => 'changes',
                    values      => {
                        id          => $uid,
                        identity_id => $id,
                        message     => $opts->{message},
                    },
                );
            }
            else {
                $uid = $self->new_change( message => $opts->{message} );
            }

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $id,
                    kind      => 'identity',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    name      => $opts->{name},
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_identity',
                values      => {
                    id        => $id,
                    change_id => $uid,
                    shortname => $opts->{shortname},
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    change_id => $uid,
                    id        => $ecmid,
                    kind      => 'entity_contact_method',
                },
            );

            $dbw->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    change_id => $uid,
                    id        => $ecmid,
                    entity_id => $id,
                    method    => $opts->{method},
                    mvalue    => bv( $opts->{value}, DBI::SQL_VARCHAR ),
                },
            );

            $dbw->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    change_id                 => $uid,
                    id                        => $id,
                    contact_id                => $id,
                    default_contact_method_id => $ecmid,
                },
            );

            $dbw->xdo(
                insert_into => 'change_deltas',
                values      => {
                    change_id         => $uid,
                    new               => 1,
                    action_format     => "new identity (%s) $opts->{name}",
                    action_topic_id_1 => $id,
                },
            );

            $dbw->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            if ( $opts->{self} ) {
                $dbw->xdo(
                    insert_into => 'bifkv',
                    values      => {
                        key         => 'self',
                        identity_id => $id,
                    },
                );
            }

            printf( "Identity created: %d\n", $id );

            # For test scripts
            $opts->{id}        = $id;
            $opts->{change_id} = $uid;
        }
    );

    return $self->ok('NewIdentity');
}

1;
__END__

=head1 NAME

=for bif-doc #create

bif-new-identity - create a new identity in the repository

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif new identity [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-new-identity> command creates a new object in the repository
representing an individual.

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of the identity.

=item METHOD

The default contact method type, typically "phone", "email", etc.

=item VALUE

The value of the default contact method, i.e. the phone number, the
email address, etc.

=item --message, -m MESSAGE

The creation message, set to "Created" by default.

=item --self

Register this identity as "myself" to be used for future changes.

=item --shortname, -s

The shortname (initials) to be shown in some outputs

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

