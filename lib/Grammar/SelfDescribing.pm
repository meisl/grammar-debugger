use v6; # this is Perl6
use Grammar::Tracer;

# Note: *every statement needs to be ended with a semicolon ';'!

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
    token literal       { <number> | <q-str> }
    token number        { '-'? \d+ ['.' \d+]? }
    token sig-symbol    {
        [ '$/'
        | '$!'
        | '$_'
        | '$' \d+
        | '$'         ['*' | '?' | '!' | '.' ]? <bare-symbol>
        | ['@' | '%'] ['*' | '?' | '!' | '.' ]? <bare-symbol>
        ]
    }

    token q-str {
        [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
        { make $/{'s'}.ast; }
    }

    token sq-str {
        [ (<-[\'\n\\]>+)
        | \\ (<[\'\\]>)
        | (\\ <-[\'\n\\]>)
        ]*
        { make $0.list.join; }
    }

    #-------------------- can parse itself up to here --------------------

    my %dq-esc = (b => "\b", r => "\r", n => "\n", f => "\f", t => "\t");

    token dq-str {
        [ (<-[\"\n\\]>+)
        | \\ (<[\"\'\\]>)
        | \\ (<-[\"\'\n\\]>)    { $0[*-1].make(%dq-esc{$0[*-1]} // (die 'unknow esc \\' ~ $0[*-1])) }
        ]*
        { make $0.map({$_.ast // $_}).list.join; }
    }

    token indirection {
        [ '.' <method-call>
        | '[' <array-index> ']'
        | '{' <hash-lookup> '}'
        ] <indirection>?
    }
    token method-call   { <bare-symbol> ['(' <arguments> ')' ]? }
    token array-index   { <term> }
    token hash-lookup   { <term> }

    rule  arguments     { [ <term> [',' <term>]* ]? }
    rule  type-decl     { <class-like> | <code-like> }
    rule  class-like    { [ 'module' | 'class' | 'grammar' ] <bare-symbol>? '{' <TOP> '}' }
    rule  code-like     { <prod-decl> | <code-decl> }
    rule  code-decl     { [ 'sub' | 'method' | 'submethod' ] <bare-symbol>? '{' <code> '}' }
    rule  prod-decl     { [ 'rule' | 'token' | 'regex' ]     <bare-symbol>? '{'  <rx>  '}' }
    rule  code          { \s* <TOP> }
    
    rule  rx            { \s* <rx-term> [ '|' <rx-term> ]* }
    rule  rx-term       { <rx-factor>+ }
    rule  rx-factor     {
        [ <rx-lit>
        | <rx-anchor>
        | <rx-braced>
        ]
        <rx-quant>?
    }
    token rx-lit        { '.'  |  '\\' [ <alpha> | <digit> | <[\'\"\\*$._]> ]  |  <q-str> }
    token rx-anchor     { '^^' | '^' | '$$' | '$' }
    token rx-quant      { '?' | '*' | '+' }
    
    token rx-braced {
        | '<' <rx-brcd-angle> '>'
        | '[' <rx> ']'
        | '(' <rx> ')'
        | '{' <code> '}'
    }
    token rx-brcd-angle { 
        [ <bare-symbol> [ '=' <bare-symbol> ]*
        | '-'? '[' <rx-cclass> ']'
        ]
    }
    token rx-cclass  { [ <-[\]\\]>+ | \\ . ]* }

}


# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<TOP>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
# ----------------------------------------------------------------------------------------------------------------------------------------
use v6; # this is Perl6
#use Grammar::Tracer;

# Note: *every statement needs to be ended with a semicolon ';'!

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
    token literal       { <number> | <q-str> }
    token number        { '-'? \d+ ['.' \d+]? }
    token sig-symbol    {
        [ '$/'
        | '$!'
        | '$_'
        | '$' \d+
        | '$'         ['*' | '?' | '!' | '.' ]? <bare-symbol>
        | ['@' | '%'] ['*' | '?' | '!' | '.' ]? <bare-symbol>
        ]
    }

    token q-str {
        [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
        { make $/{'s'}.ast; }
    }

    token sq-str {
        [ (<-[\'\n\\]>+)
        | \\ (<[\'\\]>)
        | (\\ <-[\'\n\\]>)
        ]*
        { make $0.list.join; }
    }

    #-------------------- can parse itself up to here --------------------
}
say SelfDescribing.parse($?FILE);
ENDOFHEREDOC
exit;


# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<prod-decl>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
# ----------------------------------------------------------------------------------------------------------------------------------------
token q-str {
    [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
    { make $/{'s'}.ast; }
    }
ENDOFHEREDOC
exit;


# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<prod-decl>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
# ----------------------------------------------------------------------------------------------------------------------------------------
token q-str {
    [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
    { make $/{'s'}.ast; }
}
ENDOFHEREDOC
exit;
