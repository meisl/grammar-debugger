use v6;

use Test;
use Grammar::Test::Helper;


plan *;

{ diag 'can use Grammar::Hooks restricted to lexical scope';
    use Grammar::Hooks;
    my grammar G {
        rule  TOP { <foo> }
        token foo { 'xyz' }
    }
    for parseTasks(G, :text('xyz')) -> $t {
        my $out = RemoteControl.do($t);
        is_deeply($out.lines, [], $t.perl ~ ' on hooked grammar doesn\'t output anything ')
            || diag $out.lines;
    }
}
