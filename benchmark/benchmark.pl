use v6;

use Grammar::Example::RegexTiny;

# NOTE: we DON'T "use Grammar::Tracer" *here*
#       nor "use Grammar::Debugger"
#       nor "use Grammar::Hooks"
# but rather pick 'em in their own lexical scopes below



my $t_ref;

sub test(Grammar $G, Int :$repeat = 2, Bool :$reference-time = False) {
    die "reference time already set: $t_ref "
        if $reference-time && $t_ref.defined;
    my $d;
    if $G.^can('describe') {
        $d = $G.describe;
    } else {
        $d = 'without any use Grammar::*';
        
    }
    printf('# %-120s: ', $d);
    $*OUT.flush();
    my $t = 0;
    {
        my $*OUT = class { method print(|x) {}; method flush(|x) {} };
        #my $*ERR = class { method print(|x) {}; method flush(|x) {} };

        my $s = $G.tiny-input();
        for 1..$repeat {
            $t -= nqp::p6box_n(nqp::time_n);
            $G.parse($s);
            $t += nqp::p6box_n(nqp::time_n);;
        }
        $t = $t / $repeat;
    }
    my $f = 1;
    my $which = '';
    if ($reference-time) {
        $t_ref = $t;
    } elsif $t > $t_ref {
        $f = $t / $t_ref;
        $which = 'slower';
    } else {
        $f = $t_ref / $t;
        $which = 'faster';
    }
    say sprintf(" %8.3f sec  %9.2f x %6s  (avg of %2d runs)", $t, $f, $which, $repeat);
}


# --------------------------------------------------------------------------------------
# End of preparations, actual benchmarks start here

my $t = DateTime.now;
say sprintf('## %s / %s %s on %s / %s', $t, $*PERL<compiler><name>, $*PERL<compiler><ver>, $*VM<name>, $*OS);

#$t_ref = 17.969;
if ($t_ref.defined) {
    say '#                                        with "Grammar::Hooks":    17.969 sec       1.00 x         (avg of  1 runs)';
} else {
  use Grammar::Hooks_00;
  my grammar G is RegexTiny {}
  test(G, :reference-time, :repeat(1));
}


{
  my grammar G is RegexTiny {
    method describe() { 'without any "use Grammar::*"' }
  }
  test(G, :repeat(15));
}


{
  use Grammar::Hooks_02;
  my grammar G is RegexTiny {}
  test(G, :repeat(2));
}


{
  use Grammar::Hooks_01;
  my grammar G is RegexTiny {}
  test(G, :repeat(2));
}


{
  use Grammar::Tracer_00_h00;
  my grammar G is RegexTiny {}
  test(G, :repeat(1));
}






my $old = Q:to/ENDOFHEREDOC/; # uppercase Q: NO interpolation!
---------- run perl6 ----------
#                                        with "Grammar::Hooks":    17.969 sec       1.00 x         (avg of 1 runs)
## 2014-09-15T18:21:47+0200 / rakudo 2014.03.01 on parrot / MSWin32
#                                 without any "use Grammar::*":     0.035 sec     516.68 x faster  (avg of 9 runs)
#                            with "Grammar::Hooks_noWrapParse":     0.281 sec      63.95 x faster  (avg of 1 runs)
#                                       with "Grammar::Tracer":    69.172 sec       3.85 x slower  (avg of 1 runs)

Output completed (1 min 15 sec consumed) - Normal Termination


---------- run perl6 ----------
#                                        with "Grammar::Hooks":    17.969 sec       1.00 x         (avg of 1 runs)
## 2014-09-15T18:24:55+0200 / rakudo 2014.03.01 on parrot / MSWin32
#                                 without any "use Grammar::*":     0.023 sec     796.65 x faster  (avg of 9 runs)
#                            with "Grammar::Hooks_noWrapParse":     0.266 sec      67.55 x faster  (avg of 1 runs)
#                                       with "Grammar::Tracer":    68.797 sec       3.83 x slower  (avg of 1 runs)

Output completed (1 min 15 sec consumed) - Normal Termination

---------- run perl6 ----------
## 2014-09-15T18:29:26+0200 / rakudo 2014.03.01 on parrot / MSWin32
#                                        with "Grammar::Hooks":    18.179 sec       1.00 x         (avg of 2 runs)
#                                 without any "use Grammar::*":     0.057 sec     317.70 x faster  (avg of 9 runs)
#                            with "Grammar::Hooks_noWrapParse":     0.313 sec      58.08 x faster  (avg of 1 runs)
#                                       with "Grammar::Tracer":    70.578 sec       3.88 x slower  (avg of 1 runs)

Output completed (1 min 53 sec consumed) - Normal Termination


e:\proj\perl6\Grammar-Debugger>perl6 -Ilib benchmark\benchmark.pl
## 2014-09-15T18:33:25+0200 / rakudo 2014.03.01 on parrot / MSWin32
#                                        with "Grammar::Hooks":    17.781 sec       1.00 x         (avg of 2 runs)
#                                 without any "use Grammar::*":     0.090 sec     196.84 x faster  (avg of 9 runs)
#                            with "Grammar::Hooks_noWrapParse":     0.265 sec      67.10 x faster  (avg of 1 runs)
#                                       with "Grammar::Tracer":    71.359 sec       4.01 x slower  (avg of 1 runs)


e:\proj\perl6\Grammar-Debugger>perl6 -Ilib benchmark\benchmark.pl
## 2014-09-15T19:17:50+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Grammar::Hooks_00 - find_method (newly) wraps Regexes plus &parse and &subparse                                         :    22.985 sec       1.00 x         (avg of  3 runs)
# without any "use Grammar::*"                                                                                            :     0.022 sec    1051.13 x faster  (avg of 15 runs)
# Grammar::Hooks_02 - find_method (newly) wraps Regexes but &parse and &subparse are wrapped in publish_method_cache      :     0.331 sec      69.40 x faster  (avg of  5 runs)
# Grammar::Hooks_01 - find_method (newly) wraps Regexes but NOT &parse and &subparse                                      :     0.309 sec      74.34 x faster  (avg of  5 runs)

e:\proj\perl6\Grammar-Debugger>perl6 -Ilib benchmark\benchmark.pl
## 2014-09-15T19:20:23+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Grammar::Hooks_00 - find_method (newly) wraps Regexes plus &parse and &subparse                                         :    23.146 sec       1.00 x         (avg of  3 runs)
# without any "use Grammar::*"                                                                                            :     0.021 sec    1109.22 x faster  (avg of 15 runs)
# Grammar::Hooks_02 - find_method (newly) wraps Regexes but &parse and &subparse are wrapped in publish_method_cache      :     0.322 sec      71.93 x faster  (avg of  5 runs)
# Grammar::Hooks_01 - find_method (newly) wraps Regexes but NOT &parse and &subparse                                      :     0.294 sec      78.78 x faster  (avg of  5 runs)

e:\proj\perl6\Grammar-Debugger>perl6 -Ilib benchmark\benchmark.pl
## 2014-09-15T19:21:56+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Grammar::Hooks_00 - find_method (newly) wraps Regexes plus &parse and &subparse                                         :    22.573 sec       1.00 x         (avg of  3 runs)
# without any "use Grammar::*"                                                                                            :     0.020 sec    1140.05 x faster  (avg of 15 runs)
# Grammar::Hooks_02 - find_method (newly) wraps Regexes but &parse and &subparse are wrapped in publish_method_cache      :     0.319 sec      70.85 x faster  (avg of  5 runs)
# Grammar::Hooks_01 - find_method (newly) wraps Regexes but NOT &parse and &subparse                                      :     0.297 sec      76.00 x faster  (avg of  5 runs)


---------- run perl6 ----------
## 2014-09-15T19:41:47+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Grammar::Hooks_00 - find_method (newly) wraps Regexes plus &parse and &subparse                                         :    25.031 sec       1.00 x         (avg of  1 runs)
# without any "use Grammar::*"                                                                                            :     0.020 sec    1264.20 x faster  (avg of 15 runs)
# Grammar::Hooks_02 - find_method (newly) wraps Regexes but &parse and &subparse are wrapped in publish_method_cache      :     0.319 sec      78.52 x faster  (avg of  5 runs)
# Grammar::Hooks_01 - find_method (newly) wraps Regexes but &parse and &subparse NOT wrapped (incorrect!)                 :     0.287 sec      87.09 x faster  (avg of  5 runs)
# Grammar::Tracer_00_h00 - is Hooks_00 / "use Term::ANSICOLOR"                                                            :    74.953 sec       2.99 x slower  (avg of  3 runs)

Output completed (4 min 21 sec consumed) - Normal Termination

ENDOFHEREDOC
