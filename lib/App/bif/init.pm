package App::bif::init;
use strict;
use warnings;
use parent 'App::bif::Context';
use App::bif::init::repo;
use App::bif::new::identity;
use App::bif::pull::identity;
use Log::Any '$log';
use Path::Tiny qw/path/;

our $VERSION = '0.1.0_28';

sub run {
    my $opts = shift;
    my $self = __PACKAGE__->new($opts);
    my $dir  = path('.bif')->realpath;

    return $self->err( 'DirExists', 'directory exists: ' . $dir )
      if -e $dir;

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
            directory => $dir,
        },
        sub {
            App::bif::pull::identity::run(
                {
                    @_,
                    location => $user_repo,
                    self     => 1,
                }
            );
        }
    );

    return $self->ok('Init');
}

1;
__END__

=head1 NAME

bif-init -  create a new bif repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif init [ITEM] [OPTIONS...]

=head1 DESCRIPTION

The B<bif-init> command creates a new local repository in F<.bif/>
after creating (if necessary) the system-wide user repository.
B<bif-init> does all of its work through other bif commands.  They are
wrapped by this command in order to simplify the most common
initialization scenario, which on the command-line would look something
like this:

    #!sh
    if [ ! -d $USER_REPO ]; then
        bif init repo $USER_REPO
        bif new identity --user-repo --self
    fi

    bif init repo .bif/
    bif show identity 1 --user-repo
    bif pull identity $SELF@$USER_REPO --self

See the FILES section below for the location of $USER_REPO.

=head2 Arguments & Options

=over

=item ITEM

One of the following sub-commands:

=over

=item repo

L<bif-init-repo>

=item hub

L<bif-init-hub>

=back

=back

Note that the global C<--user-repo> option does not apply in the
context of B<bif-init> and is ignored.

=head2 Errors

Attempting to initialise an existing repository is considered an error.


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


