use strict;
use warnings;
use App::bif::Pager;
use Test::More;

my $pager = App::bif::Pager->new;
isa_ok $pager, 'App::bif::Pager';

ok print("Can print regardless of whether a pager has started\n"), 'print';

if ( -t STDOUT ) {
    isnt fileno(select), fileno(STDOUT), 'default FH is not STDOUT';
    is fileno(select), fileno( $pager->fh ), 'default FH is our pager';

    ok
      printf( "### You should be seeing this in pager %s ###\n",
        $pager->pager ), 'Print to pager';

    $pager->close;
    $pager->open;
    print "And let's start the pager again\n";
    $pager = undef;
    $pager = App::bif::Pager->new;
    print "This should be a new pager as well.\n";
}
else {
    ok !$pager->fh->opened, 'No pager when no terminal';
}

done_testing();
