use v6;

use Grammar::Hooks_01;


my class Tracer_01_h01 is Hooks_01 is export {

    method describe($obj) {
        '`is Hooks_01` / NO `Term::ANSICOLOR`';
    }

    method onRegexEnter(Str $name, Int $indent) {
        say ('|  ' x $indent) ~ $name ;
    }

    method onRegexExit(Str $name, Int $indent, Match $match) {
        say ('|  ' x $indent) ~ '* ' ~
            ($match
                ?? 'MATCH' ~ self.summary($indent, $match)
                !! 'FAIL'
            )
        ;
    }

    method summary(Int $indent, Match $match) {
        my $snippet = $match.Str;
        my $sniplen = 60 - (3 * $indent);
        $sniplen > 0
            ?? ' ' ~ $snippet.substr(0, $sniplen).perl
            !! ''
    }

}

# Export this as the meta-class for the "grammar" package declarator.
my module EXPORTHOW { }
EXPORTHOW::<grammar> = Tracer_01_h01;
