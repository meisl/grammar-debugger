use v6;


class Hooks_02 is Metamodel::GrammarHOW {

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
        'Grammar::Hooks_02 - find_method (newly) wraps Regexes but &parse and &subparse are wrapped in publish_method_cache'
    }

    method publish_method_cache($obj) {
        #note '>>>publish_method_cache(' ~ $obj.^name ~ ')';
        self.add_method($obj, "describe", -> |args { self.describe(|args); });

        # role Wrapped: nothing but a tag st *we* (here) wrap only once.
        # Note that there's more to code wrapping than one might
        # think (see Routine.pm).
        # They use a role named Wrapped there, too. 
        # And it's NOT public, FOR A REASON!
        # Hence we cannot use it here - it would be
        # incorrect anyways as someone else could have
        # wrapped it before (in which case we still need
        # to wrap our own stuff around).
        my role Wrapped {};

        for <parse subparse> -> $name {
            my $meth := self.find_method($obj, $name);
            if !$meth.does(Wrapped) {
                $meth.wrap(-> |args {
                    self!resetState;
                    callsame;
                });
                $meth does Wrapped;
            }
            #note ">>>>>>>> publish_method_cache: " ~ self.name($obj) ~ ".$name ~> " ~ ($meth ~~ Any ?? $meth.perl !! '???');
        }

        # Suppress this, so we always hit find_method.
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Hooks_02;   # ~> "use Grammar::Hooks_02"