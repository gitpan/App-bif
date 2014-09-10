package App::bif::new::identity;
use strict;
use warnings;
use parent 'App::bif::Context';
use Config::Tiny;
use DBIx::ThinSQL qw/bv/;
use IO::Prompt::Tiny qw/prompt/;
use Path::Tiny qw/path/;

our $VERSION = '0.1.0_27';

sub run {
    my $self   = __PACKAGE__->new(shift);
    my $db     = $self->dbw;
    my $name   = '';
    my $email  = '';
    my $spacer = '';

    if ( $self->{self} ) {
        print "Creating \"self\" identity:\n";

        my $git_conf_file = path( File::HomeDir->my_home, '.gitconfig' );
        my $git_conf = Config::Tiny->read($git_conf_file) || {};

        $name  = $git_conf->{user}->{name}  || 'Your Name';
        $email = $git_conf->{user}->{email} || 'your@email.adddr';

        $name =~ s/(^")|("$)//g;
        $email =~ s/(^")|("$)//g;

        $spacer = '  ';
    }

    $self->{name} ||= prompt( $spacer . 'Name:', $name )
      || return $self->err( 'NameRequired', 'name is required' );

    $self->{method} ||= prompt( $spacer . 'Contact Method:', 'email' )
      || return $self->err( 'MethodRequired', 'method is required' );

    $self->{value} ||=
      prompt( $spacer . 'Contact ' . ucfirst( $self->{method} ) . ':', $email )
      || return $self->err( 'ValueRequired', 'value is required' );

    $self->{message} ||= '';

    $db->txn(
        sub {
            my $id    = $db->nextval('topics');
            my $ecmid = $db->nextval('topics');
            my $uid;

            if ( $self->{self} ) {
                $uid = $db->nextval('updates');
                $db->xdo(
                    insert_into => 'updates',
                    values      => {
                        id          => $uid,
                        identity_id => $id,
                        author      => $self->{name},
                        email       => $self->{value},
                        local       => 1,
                    },
                );
            }
            else {
                $uid = $self->new_update( message => $self->{message} );
            }

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    update_id => $uid,
                    id        => $id,
                    kind      => 'identity',
                },
            );

            $db->xdo(
                insert_into => 'func_new_entity',
                values      => {
                    id        => $id,
                    update_id => $uid,
                    name      => $self->{name},
                },
            );

            $db->xdo(
                insert_into => 'func_new_identity',
                values      => {
                    id        => $id,
                    update_id => $uid,
                },
            );

            $db->xdo(
                insert_into => 'func_new_topic',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    kind      => 'entity_contact_method',
                },
            );

            $db->xdo(
                insert_into => 'func_new_entity_contact_method',
                values      => {
                    update_id => $uid,
                    id        => $ecmid,
                    entity_id => $id,
                    method    => $self->{method},
                    mvalue    => bv( $self->{value}, DBI::SQL_VARCHAR ),
                },
            );

            $db->xdo(
                insert_into => 'func_update_entity',
                values      => {
                    update_id                 => $uid,
                    id                        => $id,
                    contact_id                => $id,
                    default_contact_method_id => $ecmid,
                },
            );

            $db->xdo(
                insert_into => 'update_deltas',
                values      => {
                    update_id         => $uid,
                    new               => 1,
                    action_format     => "new identity %s ($self->{name})",
                    action_topic_id_1 => $id,
                },
            );

            $db->xdo(
                insert_into => 'func_merge_updates',
                values      => { merge => 1 },
            );

            if ( $self->{self} ) {
                $db->xdo(
                    insert_into => 'bifkv',
                    values      => {
                        key         => 'self',
                        identity_id => $id,
                    },
                );
            }

            printf( "Identity created: %d\n", $id );

            # For test scripts
            $self->{id}        = $id;
            $self->{update_id} = $uid;
        }
    );

    return $self->ok('NewIdentity');
}

1;
__END__

=head1 NAME

bif-new-identity - create a new identity in the repository

=head1 VERSION

0.1.0_27 (2014-09-10)

=head1 SYNOPSIS

    bif new identity [NAME] [METHOD] [VALUE] [OPTIONS...]

=head1 DESCRIPTION

The C<bif new identity> command creates a new object in the repository
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

Register this identity as "myself" to be used for future updates.

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

