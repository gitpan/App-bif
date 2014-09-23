package App::bif::drop::task;
use strict;
use warnings;
use parent 'App::bif::Context';

our $VERSION = '0.1.0_28';

sub run {
    my $self = __PACKAGE__->new(shift);
    my $db   = $self->dbw;
    my $info = $self->get_topic( $self->{id}, 'task' );

    if ( !$self->{force} ) {
        print "Nothing dropped (missing --force, -f)\n";
        return $self->ok('DropNoForce');
    }

    my $uuid = substr( $info->{uuid}, 0, 8 );

    $db->txn(
        sub {
            $self->new_change( message => "drop task $info->{id} <$uuid>", );

            my $res = $db->xdo(
                delete_from => 'tasks',
                where       => { id => $info->{id} },
            );

            $db->xdo(
                insert_into => 'func_merge_changes',
                values      => { merge => 1 },
            );

            if ($res) {
                print "Dropped task: $self->{id} <$uuid>\n";
            }
            else {
                $self->err( 'NothingDropped', 'nothing dropped!' );
            }
        }
    );

    return $self->ok('DropTask');
}

1;
__END__

=head1 NAME

bif-drop-task - remove an task from the repository

=head1 VERSION

0.1.0_28 (2014-09-23)

=head1 SYNOPSIS

    bif drop task ID [OPTIONS...]

=head1 DESCRIPTION

The bif-drop-task command removes a task from the repository.

=head1 ARGUMENTS

=over

=item ID

A task ID.

=back

=head1 OPTIONS

=over

=item --force, -f

Actually do the drop. This option is required as a safety measure to
stop you shooting yourself in the foot.

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

