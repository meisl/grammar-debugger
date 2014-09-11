use v6; # this is Perl6

use Grammar::Tracer;


grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <statement> ]* }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <say-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    rule  say-stmt      { 'say' <term>? }
    token version       { 'v' \d+ ['.' \d+]? }
    token module-ident  { <bare-symbol> ['::' <bare-symbol>]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { <ident> [ '-' <ident>? ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*']? }
    token literal       { <number> | <string> }
    token number        { \d+ ['.' \d+]? }
    token string        { <sq-str> }

    #----------------------------------------
    token sq-str        { '\'' [ <-[\'\n\\]>+ | <sq-str-esc> ]* '\'' }
    token sq-str-esc    { '\\' <[\'\\bfnrt]> }

    token indirection   { 
        [
        | <method-call>
    #    | <array-index>
        ]
    }
    token method-call   { '.' <bare-symbol> ['(' <arguments> ')' ]? }
    rule  arguments     { [ <term> [',' <term>]* ]? }
    rule  type-decl     { <class-like> | <code-like> }
    rule  class-like    { [ 'module' | 'class' | 'grammar' ] <bare-symbol>? <class-like-body> }
    rule  code-like     { <production> | <regular-code> }
    rule  production    { [ 'rule' | 'token' | 'regex' ]     <bare-symbol>? <production-body>  }
    rule  regular-code  { [ 'sub' | 'method' | 'submethod' ] <bare-symbol>? <regular-code-body>  }
    rule  class-like-body { '{' <TOP> '}' }
    rule  regular-code-body { '{' <TOP> '}' }
    rule  production-body   { '{' [ <rx> | <regular-code-body> ]* '}' }
    rule  rx            { <rx-term> [ '|' <rx-term> ]* }
    rule  rx-term       { <rx-factor>+ }
    rule  rx-factor     {
        [ <rx-lit>
        | <rx-anchor>
        | <rx-call>
        | '[' <rx> ']'
        | '(' <rx> ')'
        ]
        <rx-quant>?
    }
    token rx-call       { '<' <bare-symbol> '>' }
    token rx-lit        { '\\' [<alpha> | '\'']  |  <string> }
    token rx-anchor     { '^^' | '^' | '$$' | '$' }
    token rx-quant      { '?' | '*' | '+' }

}

say SelfDescribing.parse(:rule<TOP>, q:to/ENDOFTEXT/);
use v6; # this is Perl6

#use Grammar::Tracer;


grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <statement> ]* }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <say-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    rule  say-stmt      { 'say' <term>? }
    token version       { 'v' <number> }
    token module-ident  { <bare-symbol> ['::' <bare-symbol>]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { <ident> [ '-' <ident>? ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*']? }
    token literal       { <number> | <string> }
    token number        { \d+ ['.' \d+]? }
    token string        { <sq-str> }
}
    #----------------------------------------
ENDOFTEXT

