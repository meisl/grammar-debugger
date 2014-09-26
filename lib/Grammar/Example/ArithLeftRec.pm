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
            return 'ArithLeftRec / ' ~ $metaName;
        }
    }

    method describe {
        'without any `use Grammar::*`'
    }

    method doWork(Int $scale where {$_ >= 0}) { !!! }

}

my %texts = %(
    1 => '1 - 2 + 3',
    2 => '1 - 2 + 3 * 4 + 5 - 6 - 8 / 9',
);

# Operators are left-associative, and this
# grammar produces the corresponding left-
# leaning parse-tree - although at the cost
# of extensive look-ahead as well as of 
# recursion depth proportional to the number
# operators.
grammar ArithLeftRec does Benchmarking {

    rule TOP      { ^ <expr> $ }
    regex expr    { \s* [ <term> <!before \s* <bin_op0>> 
                        | <expr> \s* <bin_op0> \s* <term> 
                        ] \s* 
                  }
    regex term    { <factor> }
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
    my grammar G is ArithLeftRec {}
    say G.doWork(1);
}
