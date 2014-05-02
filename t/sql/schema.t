use strict;
use warnings;
use lib 't/lib';
use Path::Tiny;
use App::bif::Context;
use Test::More;
use Test::Bif;

plan skip_all => 'developer-only schema extraction'
  unless -d '.git';

my $schema_dir = path(__FILE__)->parent->child('schema')->absolute;

$schema_dir->remove_tree( { safe => 0 } );
mkdir $schema_dir;
mkdir $schema_dir->child('table');
mkdir $schema_dir->child('index');
mkdir $schema_dir->child('trigger');

run_in_tempdir {
    bif(qw/ init /);
    my $ctx    = App::bif::Context->new( {} );
    my $db     = $ctx->db;
    my @tables = $db->xhashes(
        select => [ 'tbl_name', 'name', 'sql' ],
        from   => 'sqlite_master',
        where    => { type => 'table' },
        order_by => 'name',
    );

    foreach my $table (@tables) {
        next if $table->{name} =~ m/^sqlite/;
        my $file = $schema_dir->child( 'table', $table->{name} );
        $file->spew_utf8( $table->{sql} . ';' );

        my @indexes = $db->xhashes(
            select => [ 'name', 'tbl_name', 'sql' ],
            from   => 'sqlite_master',
            where    => { type => 'index', tbl_name => $table->{name} },
            order_by => 'name',
        );

        foreach my $index (@indexes) {
            next unless defined $index->{sql};
            my $file = $schema_dir->child( 'index', $index->{name} );
            $file->spew_utf8( $index->{sql} . ';' );
        }

        my @triggers = $db->xhashes(
            select => [ 'name', 'tbl_name', 'sql' ],
            from   => 'sqlite_master',
            where    => { type => 'trigger', tbl_name => $table->{name} },
            order_by => 'name',
        );

        foreach my $trigger (@triggers) {
            my $file = $schema_dir->child( 'trigger', $trigger->{name} );
            $file->spew_utf8( $trigger->{sql} . ';' );
        }

        # Try and remind ourselves that we shouldn't be editing this file
        # from the shell
        chmod 0444, $file;
        ok 1, $table->{name};
    }

};

done_testing();

