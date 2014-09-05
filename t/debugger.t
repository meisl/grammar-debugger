use v6;

use Test;
use Term::ANSIColor;
use Grammar::Debugger;


plan *;


grammar Sample {
    rule TOP { <foo> }
    token foo { 
        [
        | x
        | <bar>
        | <baz>
        ]
    }
    regex bar is breakpoint { bar }
    regex baz { baz }

    method fizzbuzz {}
}


sub test_parse($grammar, $s) { # capture output and remote-control Debugger
    my @calls = ();
    my $*OUT = class { method say(*@x) {
        @calls.push('  say(' ~ @x.map(*.perl).join(', ') ~ ');');
    }; method print(*@x) {
        @calls.push('print(' ~ @x.map(-> $s { colorstrip($s).perl }).join(', ') ~ ');');
    }; method flush(*@x) {
        @calls.push('flush(' ~ @x.map(*.perl).join(', ') ~ ')');
    } };
    my $*IN  = class {
        method get(*@x) {
            my $out = "r";
            @calls.push('  get(' ~ @x.map(*.perl).join(', ') ~ '); # ~> ' ~ $out.perl);
            print ($out ~ "\n");

            return $out;
        }
    };
    $grammar.parse($s);
    return @calls;
}


lives_ok { test_parse(Sample, 'baz') },
    'grammar.parse(...) with the debugger works';


{
    my $unsubscribe = Sample.HOW.subscribe('breakpoint', -> {});

    isa_ok $unsubscribe, Code, '.HOW.subscribe returns Code';
    lives_ok { $unsubscribe() }, 'can unsubscribe';
    lives_ok { $unsubscribe() }, 'can unsubscribe again (is a no-op)';
}

{
    my @calls = ();
    my $unsubscribe = Sample.HOW.subscribe('breakpoint', -> |args { @calls.push(args); });

    diag test_parse(Sample, 'bar').join("\n");    # regex bar marked 'is breakpoint';

    is @calls.elems, 1, 'called back at "is breakpoint"-regex';

    $unsubscribe();
    @calls = ();
    test_parse(Sample, 'bar');
    is @calls.elems, 0, 'not called back after unsubscribe';
}


#    diag 'calls (' ~ @calls.elems ~ '):';
#    diag @calls.join("\n");
