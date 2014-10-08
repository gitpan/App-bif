package App::bif::log;
use strict;
use warnings;
use feature 'state';
use locale;
use Bif::Mo;
use utf8;
use Text::Autoformat qw/autoformat/;

our $VERSION = '0.1.2';
extends 'App::bif';

sub run {
    my $self = shift;
    my $opts = $self->opts;
    my $db   = $self->db();

    if ( $opts->{id} ) {
        my $info  = $self->get_topic( $opts->{id} );
        my $class = "App::bif::log::$info->{kind}";

        if ( eval "require $class" ) {
            $opts->{path} = delete $opts->{id}
              if ( $info->{kind} eq 'project' );

            return $class->new( db => $self->db, opts => $opts )->run;
        }
        die $@ if $@;
        return $self->err( 'LogUnimplemented',
            'cannnot log type: ' . $info->{kind} );
    }

    $opts->{order} = 'time';

    require App::bif::log::repo;
    return App::bif::log::repo->new(
        opts => $opts,
        db   => $self->db,
    )->run($self);
}

sub reformat {
    my $self  = shift;
    my $text  = shift;
    my $depth = shift || 0;

    #    $depth-- if $depth;

    my $left   = 1 + 2 * $depth;
    my $indent = '    ' x $depth;

    my @result;

    foreach my $para ( split /\n\n/, $text ) {
        if ( $para =~ m/^[^\s]/ ) {
            push( @result, autoformat( $para, { left => $left } ) );
        }
        else {
            $para =~ s/^/$indent/gm;
            push( @result, $para, "\n\n" );
        }
    }

    return @result;
}

my $title;
my $path;

sub log_item {
    my $self = shift;
    my $row  = shift;
    my $type = shift;

    my $yellow = $self->colours('yellow');
    my $dark   = $self->colours('yellow');
    my $reset  = $self->colours('yellow');

    $title = $row->{title};
    $path  = $row->{path};

    ( my $id = $row->{change_id} ) =~ s/(.+)\./$yellow$1$dark\./;
    my @data = (
        $self->header(
            $dark . $yellow . 'action',
            $dark . $yellow . $row->{action},
            $row->{change_id},
        ),
        $self->header( 'From', $row->{author}, $row->{email} ),
    );

    push( @data, $self->header( 'To', $row->{path} ) ) if $row->{path};
    push( @data,
        $self->header( 'When', $self->ago( $row->{mtime}, $row->{mtimetz} ) ) );

    if ( $row->{status} ) {
        push(
            @data,
            $self->header(
                'Subject', "[$row->{path}][$row->{status}] $row->{title}"
            )
        );
    }
    else {
        push( @data,
            $self->header( 'Subject', "[$row->{path}] $row->{title}" ) );
    }

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, $self->header(@$field) );
    }

    print $self->render_table( 'l  l', undef, \@data ) . "\n";
    print $self->reformat( $row->{message} ), "\n";

    return;
}

sub log_comment {
    my $self = shift;
    my $row  = shift;
    my @data;

    state $yellow = $self->colours('yellow');
    state $dark   = $self->colours('yellow');

    push(
        @data,
        $self->header(
            $dark . $yellow . 'action',
            $dark . $yellow . $row->{action},
            $row->{change_id},
        ),
        $self->header( 'From', $row->{author}, $row->{email} ),
    );

    $path = $row->{path} if $row->{path};
    push( @data, $self->header( 'To', $path ) ) if $path;
    push( @data,
        $self->header( 'When', $self->ago( $row->{mtime}, $row->{mtimetz} ) ) );

    if ( $row->{title} ) {
        $title = $row->{title} if $row->{title};
        push( @data, $self->header( 'Subject', "$title" ) );
    }
    elsif ( $row->{status} ) {
        push( @data, $self->header( 'Subject', "[$row->{status}] $title" ) );
    }
    else {
        push( @data, $self->header( 'Subject', "↪ $title" ) );
    }

    foreach my $field (@_) {
        next unless defined $field->[1];
        push( @data, $self->header(@$field) );
    }

    print $self->render_table( 'l  l', undef, \@data, 2 * ( $row->{depth} ) )
      . "\n";

    if ( $row->{push_to} ) {
        print "[Pushed to " . $row->{push_to} . "]\n\n\n";
    }
    else {
        print $self->reformat( $row->{message}, $row->{depth} ), "\n";
    }
}

1;
__END__

=head1 NAME

=for bif-doc #history

bif-log - review the repository or topic history

=head1 VERSION

0.1.2 (2014-10-08)

=head1 SYNOPSIS

    bif log [ITEM] [OPTIONS...]

=head1 DESCRIPTION

The C<bif log> command displays repository history. Without any
arguments it is equivalent to C<bif log repo --order time>, which
displays the history of changes in the current repository in reverse
chronological order.

=head1 ARGUMENTS & OPTIONS

=over

=item ITEM

A topic kind. As a shortcut, if ITEM is a topic ID or a project PATH
then the ITEM kind will be looked up and the appropriate sub-command
run.

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

