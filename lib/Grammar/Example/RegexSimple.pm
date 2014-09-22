use v6;

# This grammar is used for benchmarking.
# !!!DO NOT CHANGE ANYTHING!!!
#
# In particular do not make it more efficient!
#
# Instead make a new grammar - which may well
# inherit from RegexSimple - and add it to the
# benchmark suite.
#
# NOTE: we DON'T "use Grammar::Tracer" *here*
#       nor "use Grammar::Debugger"
#       nor "use Grammar::Hooks"
# but rather choose those in benchmarks.pl

role Benchmarking {

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
            return 'RxSimple / ' ~ $metaName;
        }
    }

    method describe {
        'without any `use Grammar::*`'
    }

    method doWork(Int $scale where {$_ >= 0}) { !!! }

}

my $grammarBody = Q:to/ENDOFGRAMMARBODY/;
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
        [ '<' <rx_brcd_angle> '>'
        | '[' <rx> ']'
        | '(' <rx> ')'
        ]
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
ENDOFGRAMMARBODY

my @rules = $grammarBody.lines.grep({ $_ !~~ /^ \s* $/}).join("\n").split(/<?before \v \s* [rule|token|regex]>/);

my %texts = %();
for 1..@rules.elems -> $n {
    my $text ~= @rules[0..^$n].join("\n");
    %texts{$n} = $text;
}

grammar B does Benchmarking {

    method doWork(Int $scale where {$_ >= 0} ) {
        my $nRules = @rules.elems;
        #note "doWork($scale) " ~ $nRules;
        my @results = ().list;

        if $scale == 0 {
            @results.push(self.parse(''));
        } else {
            my $n = $scale;
            while $n > $nRules {
                @results.push(self.parse(%texts{$nRules}));
                $n -= $nRules;
            }
            @results.push(self.parse(%texts{$n}))
                unless $n == 0;
        }
        @results;
    }
}

my $RegexSimple = EVAL('our grammar RegexSimple is B is export {' ~ $grammarBody ~ "\n}");


#grammar _RegexSimple is export {}

#UNIT::EXPORT::DEFAULT::<RegexSimple> = $RegexSimple_raw;
#UNIT::EXPORT::ALL::<RegexSimple> = $RegexSimple_raw;

#say UNIT::EXPORT::ALL::.perl;


