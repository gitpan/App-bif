package App::bif::init::hub;
use strict;
use warnings;
use parent 'App::bif::Context';
use App::bif::init::repo;
use App::bif::new::hub;
use App::bif::new::identity;
use App::bif::pull::identity;
use Log::Any '$log';
use Path::Tiny qw/path/;

our $VERSION = '0.1.0_28';

sub run {
    my $opts = shift;
    my $self = __PACKAGE__->new($opts);
    $self->{directory} = path( $self->{directory} );
    $self->{directory}->parent->mkpath;
    $self->{directory} = $self->{directory}->realpath;

    return $self->err( 'DirExists', 'directory exists: ' . $self->{directory} )
      if -e $self->{directory};

    my $user_repo = $self->find_user_repo;

    if ( !-e $user_repo ) {
        App::bif::init::repo::run(
            {
                %$opts,
                directory => $user_repo,
                config    => 1,
            },
            sub {
                App::bif::new::identity::run(
                    {
                        @_,
                        self      => 1,
                        user_repo => 1,
                    }
                );
            }
        );
    }

    App::bif::init::repo::run(
        {
            directory => $self->{directory},
        },
        sub {
            App::bif::pull::identity::run(
                {
                    @_,
                    location => $user_repo,
                    self     => 1,
                }
            );
            App::bif::new::hub::run(
                {
                    @_,
                    name      => $self->{directory}->basename,
                    locations => [ $self->{directory} ],
                    default   => 1,
                }
            );
        }
    );

    return $self->ok('InitHub');
}

1;
__END__

=head1 NAME

bif-init-hub - create a new local hub repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif init hub [DIRECTORY] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-init-hub> command creates a new local hub repository in
F<DIRECTORY> after creating (if necessary) the system-wide user
repository.  Attempting to initialise an existing repository is
considered an error.

B<bif-init-hub> does all of its work through other bif commands.  They
are wrapped by this command in order to simplify the most common
initialization scenario, which on the command-line would look something
like this:

    #!sh
    if [ ! -d $USER_REPO ]; then
        bif init repo $USER_REPO
        bif new identity --user-repo --self
    fi

    bif init repo $DIRECTORY
    bif show identity 1 --user-repo
    bif pull identity $SELF@$USER_REPO --self
    bif new hub $BASENAME $DIRECTORY --default

See the FILES section below for the location of $USER_REPO.

=head1 ARGUMENTS & OPTIONS

=over

=item DIRECTORY

The location of the new hub repository.

=back

The global C<--user-repo> option is ignored by B<bif-init-hub>.

=head1 FILES

=over

=item $HOME/.bifu/

User repository location when not running under a Free Desktop
environment.

=item $XDG_DATA_HOME/.bifu/

User repository location when running under a Free Desktop environment.

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


