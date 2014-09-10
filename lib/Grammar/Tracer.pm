use v6;
use Term::ANSIColor;

use Grammar::InterceptedGrammarHOW;


# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"



my class TracedGrammarHOW is InterceptedGrammarHOW {
    my $indent = 0;

    method experiment() {

            #say self.callers(:include-self).map({ $_.code.^methods().grep({$_.name ne '<anon>'}).map(*.name) ~ ' ' ~ $_ }).join('');
            my @backtrace = self.callers(include-self => True);
            my $callersMethod = @backtrace[0];
            say '$callersMethod: ' ~ $callersMethod.perl;
            #say nqp::ctx();
            my Mu $sub := nqp::callercode;
            my $code;
            try {
                $code := nqp::getcodeobj($sub);
                $code := Any unless nqp::istype($code, Mu);
            };
            say $code;
            say @backtrace.join;
    
    }
    
    method find_method($obj, $name) {
        my $meth := callsame;
        return $meth unless $meth ~~ Regex;
        return sub ($c, |args) is hidden_from_backtrace {
            my Mu $result;
            my &doit = sub {
                @*dyn.push($name);
                say ">>>>>>>> = " ~ @*dyn.join(', ');;
                # Announce that we're about to enter the rule/token/regex
                self.onRegexEnter($name, $indent);

                # Call rule.
                $indent++;
                $result := $meth($c, |args);
                $indent--;
                
                # Announce that we've returned from the rule/token/regex
                my $match := $result.MATCH;
                self.onRegexExit($name, $indent, $match);
                @*dyn.pop;
            };
            if @*dyn.defined {
                &doit();
            } else {
                my @*dyn = ();
                &doit();
            }
            $result;
        };
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = TracedGrammarHOW;
