#line 1
package Module::Install::PRIVATE::App_bif;
use strict;
use warnings;
use base q{Module::Install::Base};
use File::Spec;
use Path::Tiny qw/path tempfile/;
use Pod::Select;

# Create the per-command documentation files on the fly
sub install_docs {
    my $self     = shift;
    my $args     = $self->makemaker_args;
    my $man1pods = $args->{MAN1PODS} ||= {};

    # This is an extract of init_MAN1PODS from Extutils::MM_Unix, because
    # if we set MAN1PODS then it doesn't get called
    if ( exists $args->{EXE_FILES} ) {
        foreach my $name ( @{ $args->{EXE_FILES} } ) {

            #            next unless $self->_has_pod($name);

            $man1pods->{$name} =
              path( '$(INST_MAN1DIR)', path($name)->basename . '.$(MAN1EXT)' );
        }
    }

    path('tmpdocs')->remove_tree;
    mkdir 'tmpdocs';

    my @podfiles;
    my @files = ();

    my $iter = path(qw/lib App/)->iterator( { recurse => 1 } );
    while ( my $src = $iter->() ) {
        next unless $src && -f $src;
        next if $src =~ m/\.swp/;

        my @names = File::Spec->splitdir($src);
        shift @names;    # lib/
        shift @names;    # App/
        next if @names == 1;    # ignore App::bif and App::bifsync

        my $dest = path( 'tmpdocs', join( '-', @names ) );
        next if $dest =~ m/[A-Z]/;    # ignore App::bif

        $dest =~ s/_/-/g;
        $dest =~ s/\.pm/\.pod/;
        $dest = path($dest);

        # extract the POD contents into a temporary file and read them
        # back in
        my $tmp = tempfile('XXXXXXXX');
        podselect( { -output => "$tmp" }, "$src" );
        my $pod = $tmp->slurp_utf8;

        # Convert bif::list::pro_jects names into bif-list-pro-jects
        $pod =~ s/App:://;
        $pod =~ s/::/-/g;

        path($dest)->spew_utf8($pod);
        ( my $base = $dest->basename ) =~ s/\..*//;

        $man1pods->{$dest} = path( '$(INST_MAN1DIR)', $base . '.$(MAN1EXT)' );

    }

    return;
}

1;
__END__

