use Term::ANSIColor;

# On Windows you can use perl 5 to get proper output:
# - send through Win32::Console::ANSI: perl6 MyGrammar.pm | perl -e "use Win32::Console::ANSI; print while (<>)"
# - to strip all the escape codes:     perl6 MyGrammar.pm | perl -e "print s/\e\[[0-9;]+m//gr while (<>)"

my enum InterventionPoint <EnterRule ExitRule>;

my role Breakpoint {
    method breakpoint { True }
}

my role ConditionalBreakpoint {
    has $.breakpoint-condition is rw;
    method breakpoint { True }
}

multi trait_mod:<is>(Method $m, :$breakpoint!) is export {
    $m does Breakpoint;
}

multi trait_mod:<will>(Method $m, $cond, :$break!) is export {
    $m does ConditionalBreakpoint;
    $m.breakpoint-condition = $cond;
}

role EventEmitter {
    has %.subscribers = ().hash;    # evt => callback

    method subscribe(Str $event, &callback) {
        %.subscribers.push($event => &callback);
        return -> {
            my @removed = %.subscribers{$event}.grep({ $_ !=== &callback }).eager;
            %.subscribers{$event} = @removed;
        };
    }

    method fireEvent($event, |args) {
        for @(%.subscribers{$event}) -> &callback {
            &callback(|args);
        }
    }
}

my class DebuggedGrammarHOW is Metamodel::GrammarHOW does EventEmitter {

    # Workaround for Rakudo* 2014.03.01 on Win (and maybe somewhere else, too):
    # trying to change the attributes in &intervene ...
    # ... yields # "Cannot modify an immutable value"
    # So we rather use the attribute $!state *the contents of which* we'll
    # modify instead.
    # Not as bad as it might look at first - maybe factor it out sometime.
    has $!state   = ().hash;
    has @!regexes = ().list;

    method add_method(Mu \obj, $name, $code) {
        callsame;
        if $code ~~ Regex {
            @!regexes.push($code);
        }
    }

   
    method !set-state ( # leaves untouched anything that's not defined
        Bool  :$auto-continue?,
        Int   :$indent?,
        Bool  :$stop-at-fail?,
        Str   :$stop-at-name?,
        List  :$breakpoints?,
        Hash  :$cond-breakpoints?
    ) {
        if $auto-continue.defined       { $!state{'auto-continue'}    = $auto-continue     }
        if $indent.defined              { $!state{'indent'}           = $indent;           }
        if $stop-at-fail.defined        { $!state{'stop-at-fail'}     = $stop-at-fail;     }
        if $stop-at-name.defined        { $!state{'stop-at-name'}     = $stop-at-name;     }
        if $breakpoints.defined         { $!state{'breakpoints'}      = $breakpoints;      }
        if $cond-breakpoints.defined    { $!state{'cond-breakpoints'} = $cond-breakpoints; }
    }

    method !init-state ( # sets default for  anything that's not defined
        Bool  :$auto-continue    = False,
        Int   :$indent           = 0,
        Bool  :$stop-at-fail     = False,
        Str   :$stop-at-name     = '',
        List  :$breakpoints?,
        Hash  :$cond-breakpoints?
    ) {
        self!set-state(
            :$auto-continue,
            :$indent,
            :$stop-at-fail,
            :$stop-at-name,
            :breakpoints($breakpoints
                // @!regexes.grep({ $_ ~~ Breakpoint}).map({
                       $_.name
                   }).eager)    # must evaluate - don't know why...?!
            :cond-breakpoints($cond-breakpoints
                // @!regexes.grep({ $_ ~~ ConditionalBreakpoint }).map({
                       $_.name => $_.breakpoint-condition
                   }).hash)
        );
        #say $!state{'breakpoints'}.perl;
        #say $!state{'cond-breakpoints'}.perl;
    }
    
    # just a tag to see if method is already wrapped
    my role Wrapped {}

    method find_method($obj, $name) {
        my $meth := callsame;
        #say ">>>>find_method $name";
        if $name eq any('parse', 'subparse') {
            if $meth !~~ Wrapped {
                $meth.wrap(-> |args {
                    self!init-state(); # initialize to default values
                    callsame;
                });
                $meth does Wrapped;
                #say(">>>>find_method $name: " ~ $meth.perl);
            }
        }
        return $meth unless $meth ~~ Regex;
        return -> $c, |args {
            # Issue the rule's/token's/regex's name
            say ('|  ' x $!state{'indent'}) ~ BOLD() ~ $name ~ RESET();
            
            # Announce that we're about to enter the rule/token/regex
            self.intervene(EnterRule, $name);

            $!state{'indent'}++;
            # Actually call the rule/token/regex
            my $result := $meth($c, |args);
            $!state{'indent'}--;
            
            # Dump result.
            my $match := $result.MATCH;
            
            say ('|  ' x $!state{'indent'}) ~ '* ' ~
                    (?$match ??
                        colored('MATCH', 'white on_green') ~ self.summary($match) !!
                        colored('FAIL', 'white on_red'));

            # Announce that we're about to leave the rule/token/regex
            self.intervene(ExitRule, $name, :$match);
            $result
        };
    }
    
    method intervene(InterventionPoint $point, $name, :$match) {
        # Any reason to stop?
        my $breakpoint-hit = 
            $point == EnterRule && $name eq $!state{'stop-at-name'} ||
            $point == ExitRule && !$match && $!state{'stop-at-fail'} ||
            $point == EnterRule && $name eq $!state{'breakpoints'}.any ||
            $point == ExitRule && $name eq $!state{'cond-breakpoints'}.keys.any
                && $!state{'cond-breakpoints'}{$name}.ACCEPTS($match);
        if $breakpoint-hit {
            self.fireEvent('breakpoint', $point, $name, $match);
        }
        my $stop = !$!state{'auto-continue'} || $breakpoint-hit;
        if $stop {
            my $done;
            repeat {
                my @parts = split /\s+/, prompt("> ");
                $done = True;
                given @parts[0] {
                    when '' {
                        self!set-state(
                            :auto-continue(False),
                            :stop-at-fail(False),
                            :stop-at-name(''));
                    }
                    when 'r' {
                        given +@parts {
                            when 1 {
                                self!set-state(
                                    :auto-continue(True),
                                    :stop-at-fail(False),
                                    :stop-at-name(''));
                            }
                            when 2 {
                                self!set-state(
                                    :auto-continue(True),
                                    :stop-at-fail(False),
                                    :stop-at-name(@parts[1]));
                            }
                            default {
                                usage();
                                $done = False;
                            }
                       }
                    }
                    when 'rf' {
                        self!set-state(
                            :auto-continue(True),
                            :stop-at-fail(True),
                            :stop-at-name(''));
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
                                self!set-state(:breakpoints(@rm'd));
                            }
                        }
                        elsif +@parts == 2 && @parts[1] eq 'rm' {
                            self!set-state(:breakpoints());
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
    
    method summary($match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $!state{'indent'});
        $sniplen > 0 ??
            colored(' ' ~ $snippet.substr(0, $sniplen).perl, 'white') !!
            ''
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
    
    method publish_method_cache($obj) {
        # Suppress this, so we always hit find_method.
    }
}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = DebuggedGrammarHOW;
