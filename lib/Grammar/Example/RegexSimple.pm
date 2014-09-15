use v6;

# This grammar is used for benchmarking.
# !!!DO NOT CHANGE ANYTHING!!!
#
# In particular do not make it more efficient!
#
# Instead make a new grammar - which may well
# inherit from RegexTiny - and add it to the
# benchmark suite.
#
# NOTE: we DON'T "use Grammar::Tracer" *here*
#       nor "use Grammar::Debugger"
#       nor "use Grammar::Hooks"
# but rather choose those in benchmarks.pl

role Benchmarking {

    method tiny-input   { !!! }
    method small-input  { !!! }
    method medium-input { !!! }
    method large-input  { !!! }
    method huge-input   { !!! }

    method describe {
        'without any `use Grammar::*`'
    }

    method gist {
        my $metaName = self.HOW.HOW.name(self.HOW);
        if $metaName eq 'Perl6::Metamodel::GrammarHOW' {
            my $out = 'bare ' ~ self.HOW.name(self);
            for self.^mro[1..*].map({ $_.HOW.name($_)}) -> $p {
                $out ~= ' isa ' ~ $p;
                last if $p eq 'Grammar';
            }
            return $out;
        } else {
            return $metaName;
            }
    }

}

grammar RegexSimple does Benchmarking {
    rule TOP            { ^ <rx_decl>* $ }
    rule  rx_decl       { [ 'rule' | 'token' | 'regex' ] <ident> '{' <rx> '}' }
    rule  rx            { \s* <rx_term> [ '|' <rx_term> ]* }
    rule  rx_term       { <rx_factor>+ }
    rule  rx_factor     {
        [ <rx_lit>
        | <rx_anchor>
        | <rx_braced>
        ]
        <rx_quant>?
    }
    token rx_lit        { '.'  |  '\\' [ <alpha> | <digit> | <[\'\"\\*$._]> ]  |  \' <sq_str> \' }
    token rx_anchor     { '^^' | '^' | '$$' | '$' }
    token rx_quant      { '?' | '*' | '+' }
    
    token rx_braced {
        | '<' <rx_brcd_angle> '>'
        | '[' <rx> ']'
    }
    token rx_brcd_angle {
        [ <ident> [ '=' <ident> ]* [ '=' <rx_cclass> ]?
        | <rx_cclass>
        ]
    }
    token rx_cclass  { <[+-]>?  '['  [ <-[\]\\]>+ | \\ . ]*  ']' }

    token sq_str {
        [ (<-[\'\n\\]>+)
        | \\ (<[\'\\]>)
        | (\\ <-[\'\n\\]>)
        ]*
    }

    # -- Benchmarking methods -------------------------------------------------

    method tiny-input() {
return Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!

        rule  rx_term       { <rx_factor>+ }
ENDOFHEREDOC
    }

    method small-input() {
return Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!
        rule TOP            { ^ <rx_decl>* $ }

        rule  rx_term       { <rx_factor>+ }
ENDOFHEREDOC
    }

    method medium-input() {
return Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!
        rule TOP            { ^ <rx_decl>* $ }
        rule  rx_decl       { [ 'rule' | 'token' | 'regex' ] <ident> '{' <rx> '}' }
        rule  rx            { \s* <rx_term> [ '|' <rx_term> ]* }
        rule  rx_term       { <rx_factor>+ }
ENDOFHEREDOC
    }

    method large-input() {
return Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!
        rule TOP            { ^ <rx_decl>* $ }
        rule  rx_decl       { [ 'rule' | 'token' | 'regex' ] <ident> '{' <rx> '}' }
        rule  rx            { \s* <rx_term> [ '|' <rx_term> ]* }
        rule  rx_term       { <rx_factor>+ }
        rule  rx_factor     {
            [ <rx_lit>
            | <rx_anchor>
            | <rx_braced>
            ]
            <rx_quant>?
        }
        token rx_lit        { '.'  |  '\\' [ <alpha> | <digit> | <[\'\"\\*$._]> ]  |  \' <sq_str> \' }
        token rx_anchor     { '^^' | '^' | '$$' | '$' }
        token rx_quant      { '?' | '*' | '+' }
ENDOFHEREDOC
    }

    method huge-input() {
return Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!
        rule TOP            { ^ <rx_decl>* $ }
        rule  rx_decl       { [ 'rule' | 'token' | 'regex' ] <ident> '{' <rx> '}' }
        rule  rx            { \s* <rx_term> [ '|' <rx_term> ]* }
        rule  rx_term       { <rx_factor>+ }
        rule  rx_factor     {
            [ <rx_lit>
            | <rx_anchor>
            | <rx_braced>
            ]
            <rx_quant>?
        }
        token rx_lit        { '.'  |  '\\' [ <alpha> | <digit> | <[\'\"\\*$._]> ]  |  \' <sq_str> \' }
        token rx_anchor     { '^^' | '^' | '$$' | '$' }
        token rx_quant      { '?' | '*' | '+' }
    
        token rx_braced {
            | '<' <rx_brcd_angle> '>'
            | '[' <rx> ']'
        }
        token rx_brcd_angle {
            [ <ident> [ '=' <ident> ]* [ '=' <rx_cclass> ]?
            | <rx_cclass>
            ]
        }
        token rx_cclass  { <[+-]>?  '['  [ <-[\]\\]>+ | \\ . ]*  ']' }

        token sq_str {
            [ (<-[\'\n\\]>+)
            | \\ (<[\'\\]>)
            | (\\ <-[\'\n\\]>)
            ]*
        }
ENDOFHEREDOC
    }
}
