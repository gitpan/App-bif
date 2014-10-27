use strict;
use warnings;
use App::bif::Editor;
use Test::More;

my $txt = '1+1=';
my $editor = App::bif::Editor->new( txt => $txt );

if ( -t STDOUT ) {
    isa_ok $editor, 'App::bif::Editor';

    is $editor->result, $txt . '2' . "\n", $txt . 2;
}
else {
    isa_ok $editor, 'App::bif::Editor';
    ok !$editor->pid, 'No editor when no terminal';
    is $editor->result, $txt, $txt;
}

done_testing();
