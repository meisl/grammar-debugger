use v6;


class Hooks_00 is Metamodel::GrammarHOW {

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

        # TODO: parsefile actually calls parse in the current implementation
        # - but that may change.
        # So here again we have kind of a "magic" list of method names for
        # intercepting the *start of a new parse*.
        # This should be abstracted somehow.
        if $name eq any(<parse subparse>) {
            
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

            if !$meth.does(Wrapped) {
                $meth.wrap(-> |args {
                    self!resetState;
                    callsame;
                });
                $meth does Wrapped;
            }
            #note ">>>>>>>>>>>>> find_method(" ~ self.name($obj) ~ ", $name) ~> " ~ ($meth ~~ Any ?? $meth.perl !! '???');
        }

        return $meth unless $meth ~~ Regex;

        return -> |args {
            self!onRegexEnter($meth);
            my $result := $meth(|args);
            self!onRegexExit($meth, $result);
            $result;
        };
    }

    method describe($obj) {
        'Grammar::Hooks_00 - find_method (newly) wraps Regexes plus &parse and &subparse';
    }

    method publish_method_cache($obj) {
        self.add_method($obj, "describe", -> |args { self.describe(|args); });
        #note '>>>publish_method_cache(' ~ $obj.^name ~ ')';
        # Suppress this, so we always hit find_method.
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Hooks_00;