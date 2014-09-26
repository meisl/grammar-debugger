use v6;

# This grammar is used for benchmarking.
# !!!DO NOT CHANGE ANYTHING!!!
#
# In particular do not make it more efficient!
#
# Instead make a new grammar - which may well
# inherit from this one - and add it to the
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
            return 'ArithFlat / ' ~ $metaName;
        }
    }

    method describe {
        'without any `use Grammar::*`'
    }

    method doWork(Int $scale where {$_ >= 0}) { !!! }

}

my %texts = %(
    1 => '1 - 2 + 3 * 4',
    2 => '1 - 2 + 3 * 4 + 5 - 6 - 8 / 9',
);

# Operators are left-associative, but this
# grammar produces a flat list of operands and
# operators, per precedence / parentheses level.
# Hence, for correct interpretation, a suitable
# action class must produce the correct AST from
# these lists.
# As a benefit, recursion depth for this grammar
# is proportional to nesting depth of parentheses
# pairs only.
grammar ArithFlat does Benchmarking {

    rule TOP      { ^ <expr> $ }
    rule expr     { <term>    [ <bin_op0> <term>   ]* }
    rule term     { <factor>  [ <bin_op1> <factor> ]* }
    rule factor   { <number> | '(' <expr> ')' }
    token number  {
        [    '1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9']
        ['0'|'1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9']*
    }
    token bin_op0 { '+' | '-' }
    token bin_op1 { '*' | '/' }

    method doWork(Int $scale where {$_ >= 0} ) {
        my @results = ().list;
        
        if $scale == 0 {
            @results.push(self.parse(''));
        } else {
            my $result = self.parse(%texts{$scale});
            @results.push($result);
        }
        @results;
    }
}

{
    use Grammar::Tracer_01_h04;
    my grammar G is ArithFlat {}
    G.doWork(1);
}
