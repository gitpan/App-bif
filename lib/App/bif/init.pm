package App::bif::init;
use strict;
use warnings;
use App::bif::new::repo;
use App::bif::new::identity;
use App::bif::pull::identity;
use Bif::Mo;
use File::HomeDir;
use Log::Any '$log';
use Path::Tiny qw/path/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $dir  = path( $opts->{name} ? $opts->{name} : '.bif' )->realpath;

    return $self->err( 'DirExists', 'directory exists: ' . $dir )
      if -e $dir;

    my $user_repo = path( File::HomeDir->my_home, '.bifu' )->absolute;

    if ( !-d $user_repo ) {
        App::bif::new::repo->new(
            opts => {
                %$opts,    # for global options
                config    => 1,
                directory => $user_repo,
            },
            subref => sub {
                my $dbw = shift;

                App::bif::new::identity->new(
                    dbw  => $dbw,
                    opts => {
                        %$opts,    # for global options
                        self => 1,
                    },
                )->run;
            },
        )->run;
    }

    App::bif::new::repo->new(
        opts => {
            %$opts,                # for global options
            directory => $dir,
        },
        subref => sub {
            my $dbw = shift;

            App::bif::pull::identity->new(
                dbw  => $dbw,
                opts => {
                    %$opts,        # for global options
                    location => $user_repo,
                    self     => 1,
                }
            )->run;

            if ( $opts->{name} ) {
                require App::bif::new::hub;
                App::bif::new::hub->new(
                    dbw  => $dbw,
                    opts => {
                        %$opts,    # for global options
                        name      => $dir->basename,
                        locations => [ $opts->{location} || $dir ],
                        default   => 1,
                    }
                )->run;
            }
        },
    )->run;

    return $self->ok('Init');
}

1;
__END__

=head1 NAME

=for bif-doc #init

bif-init - initialize a new bif repository

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif init [NAME] [LOCATION] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-init> command initializes a repository ready for use by other
bif commands. Different types of repository are created depending on
the arguments and options provided.

B<bif-init> does all of its work through other bif commands.  They are
wrapped by this command in order to simplify common initialization
scenarios, which are described in more detail below.

=head2 User Repository

B<bif-init> will always attempt to create the user repository
F<$HOME/.bifu> if it doesn't exist. After doing so it will also create
a new "self" identity.

=for bifcode #!sh

    bif init
    # Initialising repository: .bifu (v322)
    # Creating "self" identity:
    #   Name: [Your Name] 
    #   Short Name: [YN] 
    #   Contact Method: [email] 
    #   Contact Email: [your@email.adddr] 
    # Identity created: 1

The above is equivalent to the following:

=for bifcode #!sh
    
    USER_REPO=$HOME/.bifu
    if [ ! -d $USER_REPO ]; then
        bif new repo $USER_REPO
        bif new identity --user-repo --self
    fi

=head2 Current Working Repository

When called with no arguments a regular local repository is created in
F<$PWD/.bif>.

=for bifcode #!sh
    
    bif init
    # Creating repository: $PWD/.bif (v323)
    # Importing identity ($HOME/.bifu): received: 1/1

The individual steps for initializing a normal local repository would
look something like this:

=for bifcode #!sh

    bif new repo .bif/
    bif pull identity $USER_REPO --self

=head2 Hub Repositories

When the NAME argument is given on its own a I<local hub> repository is
initialized.

The individual steps for initializing a I<local hub> repository would
look something like this:

=for bifcode #!sh

    DIR=$PWD/$NAME
    bif new repo $DIR
    cd $DIR
    bif pull identity $USER_REPO --self
    bif new hub $NAME $DIR --default
    cd ..

=head2 Remote "Hub" Repository

A remote repository is a little different to the above cases, as it
requires that you are first have a local repository, are registered
with a hub provider, and have signed up for a plan:

=for bifcode #!sh

    bif init
    bif register PROVIDER
    bif list plans
    bif signup PLAN

Then you can initialize the remote hub at a particular host:

    bif list hosts
    bif init NAME LOCATION

The individual steps for initializing a I<remote hub> repository would
look something like this:

=for bifcode #!sh

    bif new hub $NAME
    bif push hub $NAME $HOST --default

=over

=item No arguments

A local "current" repository will be initialized in F<$PWD/.bif/>.

=item NAME only

A local "hub" repository with NAME will be initialized in
F<$PWD/NAME/>.

=item NAME and LOCATION

A local "hub" repository with NAME will be initialized in
F<$PWD/NAME/>.

A remote "hub" repository with NAME will be initialized at the remote
HOST.

=back

=head2 Arguments & Options

=over

=item NAME

The name of the new I<hub> repository

=item HOST

The host location of the new I<hub> repository when it is remote, which
must be attached to a valid plan that has been signed up for.

=back

Note that the global C<--user-repo> option does not apply in the
context of B<bif-init> and is ignored.

=head2 Errors

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


