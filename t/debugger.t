use v6;

use Test;
use Term::ANSIColor;
use Grammar::Debugger;


plan *;


grammar Sample {
    rule  TOP               { <foo> }
    token foo               { x | <bar> | <baz> }
    regex bar is breakpoint { bar }
    regex baz               { baz }

    method fizzbuzz {}
}


sub test_parse($grammar, $s, :$diag = False, :@answers = ()) { # capture output and remote-control Debugger
    my @calls = ();
    {
        my $*OUT = class { method say(*@x) {
            @calls.push('  say(' ~ @x.map(*.perl).join(', ') ~ ');');
        }; method print(*@x) {
            @calls.push('print(' ~ @x.map(-> $s { colorstrip($s).perl }).join(', ') ~ ');');
        }; method flush(*@x) {
            @calls.push('flush(' ~ @x.map(*.perl).join(', ') ~ ')');
        } };
        my $*IN  = class {
            method get(*@x) {
                my $out = (@answers.elems > 0) ?? @answers.shift !! "r";
                @calls.push('  get(' ~ @x.map(*.perl).join(', ') ~ '); # ~> ' ~ $out.perl);
                print ($out ~ "\n");

                return $out;
            }
        };
        $grammar.parse($s);
    }
    if $diag {
        diag @calls.join("\n");
    }
    return @calls;
}

{
    my @io-lines;
    lives_ok { @io-lines = test_parse(Sample, 'baz', :diag) },
        'grammar.parse(...) with the debugger works';
    is @io-lines.grep(/'get()'/).elems, 2, "stopped after TOP and at breakpoint";
    
    @io-lines = test_parse(Sample, 'baz', :diag);
    is @io-lines.grep(/'get()'/).elems, 2, "auto-continue is reset to False on 2nd parse";
}


{
    my $unsubscribe = Sample.HOW.subscribe('breakpoint', -> {});

    isa_ok $unsubscribe, Code, '.HOW.subscribe returns Code';
    lives_ok { $unsubscribe() }, 'can unsubscribe';
    lives_ok { $unsubscribe() }, 'can unsubscribe again (is a no-op)';
}

{
    my @calls = ();
    my $unsubscribe = Sample.HOW.subscribe('breakpoint', -> |args { @calls.push(args); });

    test_parse(Sample, 'bar');    # regex bar marked 'is breakpoint';

    is @calls.elems, 1, 'called back once';
    is @calls[0][1], 'bar', 'called back at "is breakpoint"-regex';
    ok @calls[0][0] ~~ 'EnterRule', "called back before entering the regex";
    #diag @calls.perl;

    $unsubscribe();
    test_parse(Sample, 'bar');
    is @calls.elems, 1, 'not called back after unsubscribe';

    $unsubscribe = Sample.HOW.subscribe('breakpoint', -> |args { @calls.push(args); });
    test_parse(Sample, 'bar');

}


#    diag 'calls (' ~ @calls.elems ~ '):';
#    diag @calls.join("\n");
