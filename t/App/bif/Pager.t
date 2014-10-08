use strict;
use warnings;
use App::bif::Pager;
use Test::More;

my $pager = App::bif::Pager->new;
isa_ok $pager, 'App::bif::Pager';

diag $pager->pager;

my $fh = $pager->fh;

ok printf( $fh "This is presumably going to a pager on fh %d\n", fileno $fh ),
  'could print to a filehandle';

done_testing();
