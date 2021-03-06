use v6;
use Grammar::Tracer;


my enum InterventionPoint <EnterRule ExitRule>;

multi trait_mod:<is>(Method $m, :$breakpoint!) is export {
    $m does role { method breakpoint { True } }
}
multi trait_mod:<will>(Method $m, $cond, :$break!) is export {
    $m does role {
        has $.breakpoint-condition is rw;
        method breakpoint { True }
    }
    $m.breakpoint-condition = $cond;
}

my class DebuggedGrammarHOW is TracedGrammarHOW {

    # Workaround for Rakudo* 2014.03.01 on Win (and maybe somewhere else, too):
    # trying to change the attributes in &intervene ...
    # ... yields # "Cannot modify an immutable value"
    # So we rather use the attribute $!state *the contents of which* we'll
    # modify instead.
    # Not as bad as it might look at first - maybe factor it out sometime.
    has $!state = (().hash does role {
        multi method reset(:@regexes = ()) {
            self<auto-continue>    = False;
            self<indent>           = 0;
            self<stop-at-fail>     = False;
            self<stop-at-name>     = '';
            self<breakpoints>      = ().list;
            self<cond-breakpoints> = ().hash;
            for @regexes -> $rx {
                if $rx.?breakpoint {
                    if $rx.?breakpoint-condition {
                        self<cond-breakpoints>{$rx.name} = $rx.breakpoint-condition;
                    } else {
                        self<breakpoints>.push($rx.name);
                    }
                }
            }
            return self;
        }
    }).reset;

    method resetState() {
        $!state.reset(:@.regexes);
    }

    method onRegexEnter(Str $name, Int $indent) {
        callsame;   # Issue rule's/token's/regex's name
        self.intervene(EnterRule, $name);
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        callsame;   # print name again plus "MATCH" or "FAIL" + some
        self.intervene(ExitRule, $name, :$match);
    }
    
    method intervene(InterventionPoint $point, $name, :$match) {
        # Any reason to stop?
        my $stop = 
            !$!state<auto-continue> ||
            $point == EnterRule && (
                $name eq $!state<stop-at-name> ||
                $name eq $!state<breakpoints>.any
            ) ||
            $point == ExitRule && (
                !$match && $!state<stop-at-fail> ||
                $name eq $!state<cond-breakpoints>.keys.any &&
                    $!state<cond-breakpoints>{$name}.ACCEPTS($match)
            )
        ;
        if $stop {
            my $done;
            repeat {
                my @parts = split /\s+/, prompt("> ");
                $done = True;
                given @parts[0] {
                    when '' {
                        $!state{'auto-continue'} = False;
                        $!state{'stop-at-fail'} = False;
                        $!state{'stop-at-name'} = '';
                    }
                    when 'r' {
                        given +@parts {
                            when 1 {
                                $!state{'auto-continue'} = True;
                                $!state{'stop-at-fail'} = False;
                                $!state{'stop-at-name'} = '';
                            }
                            when 2 {
                                $!state{'auto-continue'} = True;
                                $!state{'stop-at-fail'} = False;
                                $!state{'stop-at-name'} = @parts[1];
                            }
                            default {
                                usage();
                                $done = False;
                            }
                       }
                    }
                    when 'rf' {
                        $!state{'auto-continue'} = True;
                        $!state{'stop-at-fail'} = True;
                        $!state{'stop-at-name'} = '';
                    }
                    when 'bp' {
                        if +@parts == 2 && @parts[1] eq 'list' {
                            say "Current Breakpoints:\n" ~
                                $!state{'breakpoints'}.map({ "    $_" }).join("\n");
                        }
                        elsif +@parts == 3 && @parts[1] eq 'add' {
                            unless $!state{'breakpoints'}.grep({ $_ eq @parts[2] }) {
                                $!state{'breakpoints'}.push(@parts[2]);
                            }
                        }
                        elsif +@parts == 3 && @parts[1] eq 'rm' {
                            my @rm'd = $!state{'breakpoints'}.grep({ $_ ne @parts[2] });
                            if +@rm'd == +$!state{'breakpoints'} {
                                say "No breakpoint '@parts[2]'";
                            }
                            else {
                                $!state{'breakpoints'} = @rm'd;
                            }
                        }
                        elsif +@parts == 2 && @parts[1] eq 'rm' {
                            $!state{'breakpoints'} = [];
                        }
                        else {
                            usage();
                        }
                        $done = False;
                    }
                    when 'q' {
                        exit(0);
                    }
                    default {
                        usage();
                        $done = False;
                    }
                }
            } until $done;
        }
    }
    
    sub usage() {
        say
            "    r              run (until breakpoint, if any)\n" ~
            "    <enter>        single step\n" ~
            "    rf             run until a match fails\n" ~
            "    r <name>       run until rule <name> is reached\n" ~
            "    bp add <name>  add a rule name breakpoint\n" ~
            "    bp list        list all active rule name breakpoints\n" ~
            "    bp rm <name>   remove a rule name breakpoint\n" ~
            "    bp rm          removes all breakpoints\n" ~
            "    q              quit"
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = DebuggedGrammarHOW;
