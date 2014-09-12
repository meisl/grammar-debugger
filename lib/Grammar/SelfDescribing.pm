use v6; # this is Perl6
use Grammar::Tracer;

grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <statement> ]* }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <say-stmt> | <make-stmt>| <exit-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    rule  say-stmt      { 'say'  <term>? }
    rule  make-stmt     { 'make' <term>? }
    rule  exit-stmt     { 'exit' <term>? }
    token version       { 'v' \d+ ['.' \d+]? }
    token module-ident  { <bare-symbol> ['::' <bare-symbol>]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { <ident> [ '-' <ident>? ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*' | '?']? }
    token literal       { <number> | <q-str> }
    token number        { '-'? \d+ ['.' \d+]? }

    #-------------------- can parse itself up to here --------------------

    token q-str         { [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
                          { say 'q-str = ' ~ make($/{'s'}.ast).perl; }
                        }

    token sq-str {
        [ (<-[\'\n\\]>+)
        | \\ (<[\'\\]>)
        | (\\ <-[\'\n\\]>)
        ]*
        { make $0.list.join; }
    }

    my %dq-esc = (b => "\b", r => "\r", n => "\n", f => "\f", t => "\t");

    token dq-str {
        [ (<-[\"\n\\]>+)
        | \\ (<[\"\'\\]>)
        | \\ (<-[\"\'\n\\]>)    { $0[*-1].make(%dq-esc{$0[*-1]} // (die 'unknow esc \\' ~ $0[*-1])) }
        ]*
        { make $0.map({$_.ast // $_}).list.join; }
    }

    token indirection   {
        [ '.' <method-call>
        | '[' <array-index> ']'
        | '{' <hash-lookup> '}'
        ]
    }
    token method-call   { <bare-symbol> ['(' <arguments> ')' ]? }
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
        | <rx-angle-brkt>
        | '[' <rx> ']'
        | '(' <rx> ')'
        ]
        <rx-quant>?
    }
    token rx-lit        { '.'  |  '\\' [ <alpha> | <digit> | <[\'\"\\*$._]> ]  |  <q-str> }
    token rx-anchor     { '^^' | '^' | '$$' | '$' }
    token rx-quant      { '?' | '*' | '+' }
    token rx-angle-brkt { 
        '<'
        [ <bare-symbol> [ '=' <bare-symbol> ]*
        | '-'? '[' <rx-cclass> ']'
        ]
        '>'
    }
    token rx-cclass  { [ <-[\]\\]>+ | \\ . ]* }

}

say SelfDescribing.parse(:rule<TOP>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
use v6; # this is Perl6
use Grammar::Tracer;

grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <statement> ]* }
    token comment       { '#' \N* $$ }
    rule  statement     { [ <use-stmt> | <say-stmt> | <make-stmt>| <exit-stmt> | <term> ] ';' }
    rule  use-stmt      { 'use' [ <version> | <module-ident> ] }
    rule  say-stmt      { 'say'  <term>? }
    rule  make-stmt     { 'make' <term>? }
    rule  exit-stmt     { 'exit' <term>? }
    token version       { 'v' \d+ ['.' \d+]? }
    token module-ident  { <bare-symbol> ['::' <bare-symbol>]* }
    token term          { [ <symbol> | <literal> ] <indirection>? }
    token symbol        { <bare-symbol> | <sig-symbol> }
    token bare-symbol   { <ident> [ '-' <ident>? ]* }
    token sig-symbol    { <sig-twig> <bare-symbol> }
    token sig-twig      { ['$' | '@' | '%'] ['*' | '?']? }
    token literal       { <number> | <q-str> }
    token number        { '-'? \d+ ['.' \d+]? }

    #-------------------- can parse itself up to here --------------------
}
ENDOFHEREDOC

