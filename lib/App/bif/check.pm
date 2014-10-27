package App::bif::check;
use strict;
use warnings;
use feature 'say';
use lib 'lib';
use parent 'App::bif';
use Bif::DB::Plugin::Changes;
use DBIx::ThinSQL qw/sq qv/;
use Digest::SHA qw/sha1_hex/;
use OptArgs;
use Text::Diff qw/diff/;
use YAML::Tiny qw/Dump/;

our $VERSION = '0.1.4';

# TODO Work out how to yamlcheck utf8 chars

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db;

    my $sth = $db->xprepare_changeset_ext(
        with => 'src',
        as   => sq(
            select   => 'c.id',
            from     => 'changes c',
            order_by => 'c.id ASC',
        ),
    );

    $sth->execute;

    my $sth_uuid2id = $db->xprepare(
        select => 'c.id',
        from   => 'changes c',
        where  => 'c.uuid = ?',
    );

    # TODO this is a development aide that will stop working when
    # we start deleting from changes_pending again.
    my $sth_terms = $db->xprepare(
        select => 'up.terms',
        from   => 'changes_pending up',
        where  => 'up.change_id = ?',
    );

    my ( $del, $add, $yellow, $reset ) =
      $self->colours( 'red', 'green', 'yellow', 'reset' );

    $self->start_pager;

    my $bad = 0;
    my @bad;

    while ( my $u = $sth->changeset_ext ) {
        my $uuid = delete $u->[0]->{uuid};
        my $yaml = Dump($u);
        my $sha1 = sha1_hex($yaml);

        next if $uuid eq $sha1;
        $bad++;

        $sth_uuid2id->execute($uuid);
        my $id = $sth_uuid2id->val;

        my $msg =
            $yellow
          . "c$id: "
          . ( $u->[$#$u]->{action_format} // '** undefined action_format **' )
          . $reset;

        if ( !$opts->{verbose} ) {
            push( @bad, $msg );
            next;
        }

        say $msg;

        $sth_terms->execute($id);
        my $terms = $sth_terms->val;

        my $diff = diff \$yaml, \$terms;
        $diff =~ s/^\-/$del-/mg;
        $diff =~ s/^\+/$add+/mg;
        say $diff;

    }

    return $self->err(
        'Check', "UUID mismatch errors: %d\n%s",
        $bad, '  ' . join( "\n  ", @bad )
    ) if $bad;

    print "UUIDs ok";

    return $self->ok('Check');
}

1;
__END__

=head1 NAME

=for bif-doc #devadmin

bif-check - check all changeset UUIDs

=head1 VERSION

0.1.4 (2014-10-27)

=head1 SYNOPSIS

    bif check [OPTIONS...]

=head1 DESCRIPTION

The B<bif-check> command reports on the differences between the YAML
created by various ON INSERT triggers, and the YAML/structure generated
by the C<changeset()> method of Bif::DBW::st.

This is a mostly a tool for developers.

=head1 ARGUMENTS & OPTIONS

=over

=item --verbose, -v

Display a diff of the changes_pending.terms value and the expected YAML
text. For this to have any effect the C<DELETE FROM changes_pending>
statement must be disabled in the changes_pending BEFORE UPDATE
trigger.

=back

=head1 SEE ALSO

L<bif>(1)

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2014 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3 of the License, or (at your
option) any later version.

