use v6; # this is Perl6
use Grammar::Tracer;

# Note: *every statement needs to be ended with a semicolon ';'!

grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <stmt> ';' ]* }
    token comment       { '#' \N* $$ }
    rule  stmt          { [ <builtin-stmt> <term>? | <term> ] }
    token builtin-stmt  { 'use' | 'say' | 'exit' | 'make' }
    token term          { [ <literal> | <symbol> ] <indirection>* }
    token literal       { <number> | <q-str> | <version> | <module-ident> }
    token digits        { \d+ }
    token number        { <int=digits> ['.' <frac=digits>]? }
    token version       { 'v' <number> }
    token module-ident  { <identifier> ['::' <identifier>]* }
    token symbol        { <identifier> | <sig-sym> }

    regex sig-sym {
        [ (<star=[*]>    )
        | (<sigil=[$&@%]>) (<twigil=[*?!.^:]>?) (<identifier> | <special=[_!/]> | <capture=digits>)
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

    token indirection {
        [ '.' <method-call>
        | '[' <array-index> ']'
        | '{' <hash-lookup> '}'
        ]
    }
    token method-call   { <identifier> ['(' <arguments> ')' ]? }
    token array-index   { <term> }
    token hash-lookup   { <term> }

    #-------------------- can parse itself up to here --------------------
    
    # Let's make our own identifier token that accepts dashes "-" (but not
    # at beginning) and does NOT accept a single underscore "_" (see 
    # sig-sym / special)
    # ATTENTION: overriding ident doesn't work without (sic!) Tracer - must
    #            be some bug in Grammar or GrammarHOW.
    token identifier {
        [ '_'            <[-] + alpha>+
        | <+alpha - [_]> <[-] + alpha>*
        ]
    }

    my %dq-esc = (b => "\b", r => "\r", n => "\n", f => "\f", t => "\t");

    token dq-str {
        [ (<-[\"\n\\]>+)
        | \\ (<[\"\'\\]>)
        | \\ (<-[\"\'\n\\]>)    { $0[*-1].make(%dq-esc{$0[*-1]} // (die 'unknown esc \\' ~ $0[*-1])) }
        ]*
        { make $0.map({$_.ast // $_}).list.join; }
    }

    rule  arguments     { [ <term> [',' <term>]* ]? }
    rule  type-decl     { <class-like> | <code-like> }
    rule  class-like    { <class-kind> <identifier>? '{' <TOP> '}' }
    token class-kind    {  'module' | 'class' | 'grammar' }
    rule  code-like     { <prod-decl> | <code-decl> }
    rule  code-decl     { <code-kind> <identifier>? '{' <code> '}' }
    token code-kind     { 'sub' | 'method' | 'submethod' }
    rule  prod-decl     { <prod-kind> <identifier>? '{'  <rx>?  '}' }
    token prod-kind     { 'rule' | 'token' | 'regex' }
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
        [ <identifier> [ '=' <identifier> ]* [ '=' <rx-cclass> ]?
        | <rx-cclass>
        ]
    }
    token rx-cclass  { <[+-]>?  '['  [ <-[\]\\]>+ | \\ . ]*  ']' }

}



# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<TOP>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
use v6; # this is Perl6
use Grammar::Tracer;

# Note: *every statement needs to be ended with a semicolon ';'!

grammar SelfDescribing {
    rule  TOP           { \s* [ <comment> | <type-decl> | <stmt> ';' ]* }
    token comment       { '#' \N* $$ }
    rule  stmt          { [ <builtin-stmt> <term>? | <term> ] }
    token builtin-stmt  { 'use' | 'say' | 'exit' | 'make' }
    token term          { [ <literal> | <symbol> ] <indirection>* }
    token literal       { <number> | <q-str> | <version> | <module-ident> }
    token digits        { \d+ }
    token number        { <int=digits> ['.' <frac=digits>]? }
    token version       { 'v' <number> }
    token module-ident  { <identifier> ['::' <identifier>]* }
    token symbol        { <identifier> | <sig-sym> }

    regex sig-sym {
        [ (<star=[*]>    )
        | (<sigil=[$&@%]>) (<twigil=[*?!.^:]>?) (<identifier> | <special=[_!/]> | <capture=digits>)
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

    token indirection {
        [ '.' <method-call>
        | '[' <array-index> ']'
        | '{' <hash-lookup> '}'
        ]
    }
    token method-call   { <identifier> ['(' <arguments> ')' ]? }
    token array-index   { <term> }
    token hash-lookup   { <term> }

    #-------------------- can parse itself up to here --------------------
}
ENDOFHEREDOC
exit;



# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<type-decl>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
regex sig-sym {
    [ (<star=[*]>    )
    | (<sigil=[$&@%]>) (<twigil=[*?!.^:]>?) (<identifier> | <special=[_!/]> | <capture=digits>)
    ]
}
ENDOFHEREDOC
exit;



# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<stmt-list>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
$0; $1; $2; $42;
$_scalar-with-underscore;
$_; $/; $!;
*;
$scalar;
$scalar-with-dashes;
$!private;
$.self-method;
$^implicit-positional-param;
$:implicit-named-param;
$?compile-time-const;
$*dynamic;
ENDOFHEREDOC
exit;



# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<prod-decl>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
token q-str {
    [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
    { make $/{'s'}.ast; }
    }
ENDOFHEREDOC
exit;



# ----------------------------------------------------------------------------------------------------------------------------------------
say SelfDescribing.parse(:rule<prod-decl>, Q:to/ENDOFHEREDOC/); # uppercase Q: NO interpolation!
token q-str {
    [ \' <s=sq-str> \' | \" <s=dq-str> \" ]
    { make $/{'s'}.ast; }
}
ENDOFHEREDOC
exit;
