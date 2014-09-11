use v6; # this is Perl6

use Grammar::Tracer;


grammar SelfDescribing {
    rule  TOP           { ^ [ <comment> | <statement> ]* $ }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    token version       { 'v' \d+ ['.' \d+]? }
    token module-ident  { <alpha>+ ['::' <alpha>+]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { [ <alpha> | '_' ] [ '-' | '_' | <alpha> ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*']? }
    token literal       { ... }
    token indirection   { 
        [
        | <method-call>
    #    | <array-index>
        ]
    }
    token method-call   { '.' <bare-symbol> ['(' <arguments> ')' ]? }
    rule  arguments     { [ <term> [',' <term>]* ]? }
}

SelfDescribing.parse(q:to/ENDOFTEXT/);
use v6; # this is Perl6

use Grammar::Debugger;

SelfDescribing.parsefile($*FILE);
ENDOFTEXT
