
my class Tracer_01_standalone is Metamodel::GrammarHOW {

    method describe($obj) {
        '!INCORRECT! as it was but NO `Term::ANSICOLOR` and *like* `Hooks_01` but does all on itself'
            ~ ' (directly inherits `Metamodel::GrammarHOW`, no `onRegexEnter`... )';
    }

    my $indent = 0;
    
    method find_method($obj, $name) {
        my $meth := callsame;
        return $meth unless $meth ~~ Regex;
        return -> $c, |args {
            # Method name.
            say ('|  ' x $indent) ~ $name;
            
            # Call rule.
            $indent++;
            my $result := $meth($obj, |args);
            $indent--;
            
            # Dump result.
            my $match := $result.MATCH;
            say ('|  ' x $indent) ~ '* ' ~
                ($result.MATCH
                    ?? 'MATCH' ~ summary($match)
                    !! 'FAIL' ~ 'white on_red');
            $result;
        }
    }
    
    sub summary($match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0
            ?? ' ' ~ $snippet.substr(0, $sniplen).perl
            !! ''
    }
    
    method publish_method_cache($obj) {
        self.add_method($obj, "describe", -> |args { self.describe(|args); });
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Tracer_01_standalone;