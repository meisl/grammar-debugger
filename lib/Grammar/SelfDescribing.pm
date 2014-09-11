use v6; # this is Perl6

use Grammar::Tracer;


grammar SelfDescribing {
    rule  TOP           { [ <comment> | <type-decl> | <statement> ]* }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <say-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    rule  say-stmt      { 'say' <term>? }
    token version       { 'v' \d+ ['.' \d+]? }
    token module-ident  { <alpha>+ ['::' <alpha>+]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { [ <alpha> | '_' ] [ '-' | '_' | <alpha> ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*']? }
    token literal       { \d+ } # <<<<<<<<<<
    token indirection   { 
        [
        | <method-call>
    #    | <array-index>
        ]
    }
    token method-call   { '.' <bare-symbol> ['(' <arguments> ')' ]? }
    rule  arguments     { [ <term> [',' <term>]* ]? }
    rule  type-decl     { <type-kind> <type-name>? '{' <type-body> '}' }
    token type-kind     { 'grammar' | 'rule' | 'token' | 'regex' }
    token type-name     { <bare-symbol> }
    rule  type-body     { <type-decl>* }
}

say SelfDescribing.parse(q:to/ENDOFTEXT/);
use v6; # this is Perl6

use Grammar::Debugger;

grammar SelfDescribing {
    rule  TOP           {  }
}

say SelfDescribing.parsefile($*FILE);
ENDOFTEXT
