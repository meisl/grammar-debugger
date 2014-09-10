use v6;

use Term::ANSIColor;


role Timed {
    has @.times = ();
    multi method time() {
        self.time(0);    # time of last execution
    }
    multi method time(Int:D $offset) {
        ($offset >= @!times.elems) ?? Nil !! @!times[*-($offset + 1)];
    }
}

role MeMyselfAndI {}

multi trait_mod:<is>(Method $m, :$meMyselfAndI!) {
    # decorate method with tag role
    # Note -v the *upper-case* M for the role's name
    $m does MeMyselfAndI;
}

multi trait_mod:<is>(Method $m, :$timed!) {
    $m does Timed;
    $m.wrap(-> |args {
        my $time = -nqp::p6box_n(nqp::time_n);
        my $result = callsame;
        $time += nqp::p6box_n(nqp::time_n);
        say "#######################################push: $time onto " ~ $m.times.perl;
        $m.times.push($time);
        $result;
    });
}

class InterceptedGrammarHOW is Metamodel::GrammarHOW {

    method callers(Bool :$include-self = True)
        is meMyselfAndI
        #  ^ note the *lower-case* m for the trait_mod
        # - as opposed to the role's name
        is timed
    {
        my $time = nqp::p6box_n(nqp::time_n);
        my $meMySelfAndI;
        my $fromHere = -Inf;    # unknown
        my @frames = Backtrace.new.grep({
            my $take;
            if $fromHere < 0 {
                if $_.code ~~ MeMyselfAndI { # is it me?
                    $meMySelfAndI := $_.code;
                    say '----------------------------' ~ $meMySelfAndI.perl;
                    $fromHere = 0;
                    $take = False;
                }
            } else {
                $fromHere++;
                $take = ( ($fromHere == 1) ?? $include-self !! True )
                    && (!$_.is-hidden
                        || ($_.code ~~ Regex)
                    );
            }
            $take;
        }).eager;
        $time = ((nqp::p6box_n(nqp::time_n) - $time) * 1000).Int;
        return @frames;
    }

    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }

    method onRegexEnter(Str $name, Int $indent) {
        # Issue the rule's/token's/regex's name
        say ('|  ' x $indent) ~ BOLD() ~ $name ~ RESET();
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        say ('|  ' x $indent) ~ '* ' ~
            ($match ??
                colored('MATCH', 'white on_green') ~ self.summary($match, $indent) !!
                colored('FAIL', 'white on_red'));
    }

    method summary(Match $match, Int $indent) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
    }

}

