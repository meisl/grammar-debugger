use v6;

use Grammar::Example::RxSimple;

subset Nat of Int where { $_ >= 0 }

sub nqpTime { nqp::p6box_n(nqp::time_n) }

class GrammarBenchmark {
    has Grammar:T   $.grammarType;
    has             $.metaName;
    has Grammar:T   $!workGrammar;
    has             $!compileTime;
    has             &!runner;

    method grammarName {  $!grammarType.^name  }

    method useStmt {
        $!metaName
            ?? "use Grammar::$!metaName;"
            !! '#`{no "use XXX;" whatsoever};';
    }

    method dummyGrammarName {
        self.grammarName ~ '_' ~ (self.metaName // '')
    }

    method name {
        self.grammarName
            ~ (self.metaName ?? ' / ' ~ self.metaName !! '')
    }

    method declaration {
        self.useStmt 
            ~ ' my grammar ' ~ self.dummyGrammarName
            ~ ' is ' ~ self.grammarName ~ ' {};';
    }

    method factoryStr {
        'sub { ' ~ self.declaration 
            ~ ' return ' ~ self.dummyGrammarName
            ~ '; }';
    }

    method compileTime {
        self.workGrammar;
        $!compileTime;
    }

    method workGrammar {
        unless $!workGrammar {
            $!compileTime = -nqpTime;
            my &factory = EVAL(self.factoryStr);
            $!workGrammar = &factory();
            $!compileTime += nqpTime;
        }
        $!workGrammar;
    }

    method runner {
        &!runner // &!runner = sub (Nat $scale) {
            my $g = self.workGrammar;   # don't include compile time
            my $t = -nqpTime;
            my $result := $g.doWork($scale);
            $t += nqpTime;
            return ($t, self.compileTime, $result);
        };
    }

    method run(Nat $scale, Bool :$captureOUT = True) {
        my @result;
        if $captureOUT {
            my $*OUT = class { method print(|x) {}; method flush(|x) {} };
            #my $*ERR = class { method print(|x) {}; method flush(|x) {} };
            @result = self.runner()($scale);
        } else {
            @result = self.runner()($scale);
        }
        @result;
    }

    method Str {
        sprintf('%s (%4.3f s)',
            self.name,
            self.compileTime,
        );
    }
}

sub makeBenchmarks(:@hooks, :@tracers, :@grammars) {
    my @hookNames = @hooks.map({
        sprintf("Hooks_%02d", $_);
    });
    my @tracerNames = (@tracers X @hooks).tree.map({
        sprintf("Tracer_%02d_h%02d", @$_)
    });

    # put in Any so we have the bare thing as well:
    my @metaNames = (Any, @hookNames, @tracerNames);

    my @benchmarks = (@grammars X @metaNames).tree.map({
        GrammarBenchmark.new(:grammarType($_[0]), :metaName($_[1]));
    });


    return @benchmarks;
}

my @benchmarks = makeBenchmarks(
    :hooks<1 4>,
    :tracers<0 1>,
    :grammars(
        RxSimple,
#        ArithLeftRec,
#        ArithChain,
    )
);
say @benchmarks.elems ~ ' benchmarks';

say @benchmarks.join("\n");

my $b := @benchmarks[6];
say $b.run(2);
exit;
