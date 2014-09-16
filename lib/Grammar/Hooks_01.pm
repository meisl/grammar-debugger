use v6;


class Hooks_01 is Metamodel::GrammarHOW {

    # TODO: associate state to the right thing, sometime...
    has $!state = (().hash does role {
        multi method reset() {
            self<indent> = 0;
            return self;
        }
    }).reset;

    method !resetState() {
        $!state.reset();    # reset our own
        self.resetState;    # tell subclass to reset their's
    }

    method !onRegexEnter(Method $m) {
        # inform subclass about it:
        self.onRegexEnter($m.name, $!state<indent>);
        $!state<indent>++; # let's *explicitly* put the *post*-increment here!
    }

    method !onRegexExit(Method $m, Mu $result) {
        # inform subclass about it:
        --$!state<indent>; # let's *explicitly* put the *pre*(sic!)-decrement here!
        self.onRegexExit($m.name, $!state<indent>, $result.MATCH);
    }

    ## those are to be overridden by the subclass:
    method resetState() {}
    method onRegexEnter(Str $name, Int $indent) {}
    method onRegexExit(Str $name, Int $indent, Match $match) {}

# -----------------------------------------------------------------------------

    has @.regexes = ().list;

    method add_method(Mu $obj, $name, $code) {
        #note '>>>add_method(' ~ self.name($obj) ~ ', ' ~ $name.perl ~ ', ' ~ $code.^name ~ ')';

        @.regexes.push($code) if $code ~~ Regex;
        return callsame;
    }


    method find_method($obj, $name) {
        my $meth := callsame;
        return $meth unless $meth ~~ Regex;

        return -> |args {
            self!onRegexEnter($meth);
            my $result := $meth(|args);
            self!onRegexExit($meth, $result);
            $result;
        };
    }

    method describe($obj) {
        '!INCORRECT! `find_method` wraps Regexes freshly on each call but `&(sub)parse` are NOT wrapped';
    }

    method publish_method_cache($obj) {
        #note '>>>publish_method_cache(' ~ $obj.^name ~ ')';
        self.add_method($obj, "describe", -> |args { self.describe(|args); });
        
        #Suppress this, so we always hit find_method.
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Hooks_01;   # ~> "use Grammar::Hooks_01"