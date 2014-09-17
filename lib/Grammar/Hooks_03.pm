use v6;


class Hooks_03 is Metamodel::GrammarHOW {

    # TODO: associate state to the right thing, sometime...
    has $!state = (().hash does role {
        multi method reset() {
            self<indent> = 0;
            return self;
        }
    }).reset;


    method !onCall(Code:D $r, Capture $args) {
        if $r ~~ Regex {
            self.onRegexEnter($r.name, $!state<indent>);
            $!state<indent>++; # let's *explicitly* put the *post*-increment here!
        } elsif $r.name eq any(<parse subparse>) {
            $!state.reset();    # reset our own
            self.resetState;    # tell subclass to reset their's
        }
    }

    method !onReturn(Code:D $r, Capture $args, Mu $result) {
        if $r ~~ Regex {
            --$!state<indent>; # let's *explicitly* put the *pre*(sic!)-decrement here!
            self.onRegexExit($r.name, $!state<indent>, $result.MATCH);
        }
    }

    method !onException(Code:D $routine, Capture:D $args, Exception:D $exception) {
        note ">>>> $routine threw $exception";
    }


    ## those are to be overridden by the subclass:
    method resetState() {}
    method onRegexEnter(Str $name, Int $indent) {}
    method onRegexExit(Str $name, Int $indent, Match $match) {}

# -----------------------------------------------------------------------------

    has @.regexes = ().list;

    method add_private_method(Mu \obj, $name, $code) {
        #note '>>>add_private_method(' ~ self.name(\obj) ~ ', ' ~ $name.perl ~ ', ' ~ $code.^name ~ ')';
        return callsame;
    }

    method add_method(Mu \obj, $name, $code) {
        #note '>>>add_method(' ~ self.name(\obj) ~ ', ' ~ $name.perl ~ ', ' ~ $code.^name ~ ')';
        #note $code.signature.perl;

        # Beware: .clone plus .wrap does not always work!

        my $lambda = sub (|args) is hidden_from_backtrace {
            self!onCall($code, args);
            my $result;
            try {
                $result := $code(|args);
            }
            if $!.defined {
                self!onException($code, args, $!);
                $!.rethrow;
            } else {
                self!onReturn($code, args, $result);
                $result;
            }
        };
        @.regexes.push($code)
            if $code ~~ Regex;

        return callwith(\obj, $name, $lambda);
    }

    method describe(Mu: |args) {
        'Regexes and `&(sub)parse` wrapped only once each, `find_method` NOT overridden but method cache still disabled'
    }

    method publish_method_cache($obj) {
        #note '>>>publish_method_cache(' ~ $obj.^name ~ ')';

        # So far, any methods declared in this class already have been wrapped in add_method.
        # Now let's go through all the methods we have inherited and override them with
        # interception code:
        
        my %skip = self.method_table($obj);
       
        
        #note %skip.map(*.perl).join("\n");
        for self.methods($obj).grep({ $_ ~~ Regex  ||  $_.name eq any(<parse subparse>) }) -> $m {
            my Str $name = $m.name;
            #note 'skipped: ' ~ $name if %skip{$name}.defined;
            next if %skip{$name}.defined;
            %skip{$name} = $m;
            self.add_method($obj, $name, $m);   # add_method will NOT add it as such, neither use Routine.wrap
        }
        #note %skip.map(*.perl).join("\n");

        self.add_method( $obj, "describe", -> |args { self.describe(|args) } );

        # Suppress this, so we always hit find_method.
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Hooks_03;