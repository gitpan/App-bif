package App::bif::init;
use strict;
use warnings;
use Bif::Mo;
use Path::Tiny qw/cwd path/;

our $VERSION = '0.1.4';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dir  = cwd->child( $opts->{name} ? $opts->{name} . '.bif' : '.bif' );

    return $self->err( 'DirExists', 'directory exists: ' . $dir )
      if -e $dir;

    require File::HomeDir;
    my $user_repo = path( File::HomeDir->my_home )->child('.bifu');

    $self->dispatch(
        'App::bif::new::repo',
        {
            opts => {
                config    => 1,
                directory => $user_repo,
            },
            subref => sub {

                # This $self is a new_repo with a valid db handle
                my $self = shift;

                $self->dispatch(
                    'App::bif::new::identity',
                    {
                        opts => {
                            %$opts,    # for global options
                            self => 1,
                        },
                    }
                );
            },
        }
    ) if !-d $user_repo;

    $self->dispatch(
        'App::bif::new::repo',
        {
            opts   => { directory => $dir },
            subref => sub {

                # This $self is a new_repo with a valid db handle
                my $self = shift;
                $self->dispatch(
                    'App::bif::pull::identity',
                    {
                        opts => {
                            location => $user_repo,
                            self     => 1,
                        },
                    },
                );

                $self->dispatch(
                    'App::bif::new::hub',
                    {
                        opts => {
                            name      => $opts->{name},
                            locations => [ $opts->{location} || $dir ],
                            default   => 1,
                        },
                    }
                ) if $opts->{name};
            },
        },
    );

    return $self->ok('Init');
}

1;
__END__

=head1 NAME

=for bif-doc #init

bif-init - initialize a new bif repository

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif init [NAME] [LOCATION] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-init> command initializes a repository ready for use by other
bif commands. The repository type - Working, Local Hub, or Remote Hub -
depends on the arguments given. In addition, a special User repository
will always be created if it doesn't exist.

All of the work is actually performed by other commands. They are
wrapped by B<bif-init> in order to simplify common initialization
scenarios, each of which is described in more detail below.

=head2 User Repository

If the user repository (F<$HOME/.bifu>) does not exist B<bif-init> will
initialize it with a "self" identity before doing anything else.

=for bifcode #!sh

    bif init
    # Initialising repository: .bifu (v322)
    # Creating "self" identity:
    #   Name: [Your Name] 
    #   Short Name: [YN] 
    #   Contact Method: [email] 
    #   Contact Email: [your@email.adddr] 
    # Identity created: 1

=begin comment

The above is equivalent to the following:

=for bifcode #!sh
    
    USER_REPO=$HOME/.bifu
    if [ ! -d $USER_REPO ]; then
        bif new repo $USER_REPO
        bif new identity --user-repo --self
    fi

=end comment

After the user repository check B<bif-init> continues with the intended
action.

=head2 Working (Normal) Repository

When called with no arguments a working repository is created in
F<$PWD/.bif> and the "self" identity is imported from the User
repository.

=for bifcode #!sh
    
    bif init
    # Creating repository: $PWD/.bif (v323)
    # Importing identity ($HOME/.bifu): received: 1/1

=begin comment

The individual steps for initializing a normal local repository would
look something like this:

=for bifcode #!sh

    bif new repo .bif/
    bif pull identity $USER_REPO --self

=end comment

The current working repository is where most project management actions
take place.

=head2 Local Hub Repository

When the NAME argument is given on its own a I<local> hub repository is
initialized in F<NAME.bif>.

=for bifcode #!sh

    bif init myhub
    # Creating repository: myhub.bif (v323)
    # Importing identity ($HOME/.bifu): received: 1/1
    # Hub created: myhub

=begin comment

For the above case the individual steps would look something like this:

=for bifcode #!sh

    DIR=$PWD/$NAME
    bif new repo $DIR
    cd $DIR
    bif pull identity $USER_REPO --self
    bif new hub $NAME $DIR --default
    cd ..

=end comment

A purely local hub repository is really only useful for debugging
synchonization operations, or if several people are working on a
project together inside a single machine. The L<bif-pull-hub> command
is used to "register" a local hub with the current working repository:

=for bifcode #!sh
    
    bif pull hub myhub.bif
    # myhub.bif: received: 2/2
    # Hub pulled: myhub

=head2 Remote Hub Repository

Initializing a I<remote> hub repository can only be performed from a
previously initialized working repository. It also requires that you
have registered with a hub provider and have signed up for a hosting
plan.

=for bifcode #!sh

    bif init
    bif pull provider PROVIDER
    bif list plans
    bif signup PLAN

You can initialize a remote hub by specifying the provider's host as
the LOCATION.

    bif list hosts
    bif init myhub host.provider

=head1 ARGUMENTS & OPTIONS

=over

=item NAME

The name of a new hub repository

=item LOCATION

The location of a new I<remote> hub repository.

=back

Note that the global C<--user-repo> option does not apply in the
context of B<bif-init> and is ignored.

=head1 ERRORS

=over

=item DirExists

Attempting to initialise an existing repository is considered an error.

=back

=head1 FILES

=over

=item $HOME/.bifu/

Default user repository location.

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


