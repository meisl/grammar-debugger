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
    rule  type-decl     { <class-like> | <code-like> }
    rule  class-like    { [ 'module' | 'class' | 'grammar' ] <bare-symbol>? <class-like-body> }
    rule  code-like     { <production> | <regular-code> }
    rule  production    { [ 'rule' | 'token' | 'regex' ]     <bare-symbol>? <production-body>  }
    rule  regular-code  { [ 'sub' | 'method' | 'submethod' ] <bare-symbol>? <regular-code-body>  }
    rule  class-like-body { '{' <TOP> '}' }
    rule  regular-code-body { '{' <TOP> '}' }
    rule  production-body   { '{' [ <regex-body> | <regular-code-body> ]* '}' }
    rule  regex-body    { [ [ <rx-call> | <rx-lit> | <rx-anchor> ] <rx-quant>? ]+ }
    token  rx-call      { '<' <bare-symbol> '>' }
    token rx-lit        { '\\d' | '\\N' }
    token rx-anchor     { '^^' | '^' | '$$' | '$' }
    token rx-quant      { '?' | '*' | '+' }
}

say SelfDescribing.parse(q:to/ENDOFTEXT/);
use v6; # this is Perl6

use Grammar::Debugger;

grammar SelfDescribing {
    rule  TOP           { <comment> }
}

say SelfDescribing.parsefile($*FILE);
ENDOFTEXT
