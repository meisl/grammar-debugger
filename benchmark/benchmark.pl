use v6;

use Grammar::Example::RxSimple;

# NOTE: we DON'T "use Grammar::Tracer" *here*
#       nor "use Grammar::Debugger"
#       nor "use Grammar::Hooks"
# but rather pick 'em in their own lexical scopes below


my @scales = <0 1 2 3 4 5 6 7 8 12 16 20 24 28 32 40 48 56 64 96 128 192 256 384 512>;

my $scale = 2;
# tiny:     1
# small:    2
# medium:   4
# large:    8
# huge:    12



my $t_ref;
my @legend-exercises = ();
sub test(Grammar $G where {$_ ~~ Benchmarking}, Int :$repeat = 2, Bool :$reference-time = False) {
    die "reference time already set: $t_ref "
        if $reference-time && $t_ref.defined;
    
    my $gist = $G.gist.substr(0, 35);
    printf('# %-35s ', $gist ~ ':' );
    $*OUT.flush();
    @legend-exercises.push( ($gist => $G.describe));

    my $ttl = 0;
    my @raw_times = @();
    {
        my $*OUT = class { method print(|x) {}; method flush(|x) {} };
        #my $*ERR = class { method print(|x) {}; method flush(|x) {} };

        for 1..$repeat {
            my $t = -nqp::p6box_n(nqp::time_n);
            $G.doWork($scale);
            $t += nqp::p6box_n(nqp::time_n);
            @raw_times.push($t);
            $ttl += $t;
        }
        $ttl = $ttl / $repeat;
    }
    my $f = 1;
    my $which = 'reference';
    if ($reference-time) {
        $t_ref = $ttl;
    } elsif $ttl > $t_ref {
        $f = $ttl / $t_ref;
        $which = 'slower :(';
    } else {
        $f = $t_ref / $ttl;
        $which = 'FASTER :D';
    }
    my $summary = sprintf(" %8.3f sec  %9.2f x %6s  %9.2f  (avg'd %2d runs)", $ttl, $f, $which, $scale/$ttl, $repeat);
    say $summary;
}
# `Grammar::Hooks_02 - find_method wraps Regexes but &(sub)parse wrapped in publish_method_cache:     0.054 sec      22.94 x faster  (avg of  2 runs)

# --------------------------------------------------------------------------------------
# End of preparations, actual benchmarks start here

my $t = DateTime.now;
say sprintf("##### %s / %s %s on %s / %s / scale: %d\n```", $t, $*PERL<compiler><name>, $*PERL<compiler><ver>, $*VM<name>, $*OS, $scale);


$t_ref = 17.969;
if ($t_ref.defined) {
    say '#                                        with "Grammar::Hooks":    17.969 sec       1.00 x         (avg of  1 runs)';
} else {
  use Grammar::Hooks_00;
  my grammar G is RxSimple {}
  test(G, :reference-time, :repeat(1));
}

{ test(RxSimple, :repeat(2));
}

{ use Grammar::Hooks_01;
  my grammar G is RxSimple {}
  test(G, :repeat(5));
}

{ use Grammar::Hooks_02;
  my grammar G is RxSimple {}
  test(G, :repeat(5));
}

{ use Grammar::Hooks_03;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}

{ use Grammar::Hooks_04;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}

# ----------------------------------------

{ use Grammar::Tracer_01_h01;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

{ use Grammar::Tracer_01_h02;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}

{ use Grammar::Tracer_01_h03;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}

{ use Grammar::Tracer_01_h04;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}
exit;


# --- Hooks variants ----------------------------------------------------------
exit;
# --- Tracer variants ---------------------------------------------------------

# --- Tracer_00 (with ANSIColor) ------------------------------

{ use Grammar::Tracer_00_standalone;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

{ use Grammar::Tracer_00_h00;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

{ use Grammar::Tracer_00_h01;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

{ use Grammar::Tracer_00_h02;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

{ use Grammar::Tracer_00_h03;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}

# --- Tracer_01 (no ANSIColor) --------------------------------

{ use Grammar::Tracer_01_standalone;
  my grammar G is RxSimple {}
  test(G, :repeat(2));
}

{ use Grammar::Tracer_01_h00;
  my grammar G is RxSimple {}
  test(G, :repeat(1));
}


say "\n```\n----\n###### Legend:";
say '  * Tasks';
say '    * **Rx**: `Grammar::Example::RxSimple`: basic regex declarations, eg `rule TOP { ^ <foo>* $ }`; able to parse its own body (!)';
say '  * Exercises';
say @legend-exercises.map({ '    * **' ~ $_.key ~ ':** ' ~ $_.value}).join("\n");




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


---------- run perl6 ----------
## 2014-09-15T21:27:38+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Grammar::Hooks_00 - find_method wraps Regexes plus &(sub)parse                                                          :     5.937 sec       1.00 x         (avg of  1 runs)
# without any "use Grammar::*"                                                                                            :     0.008 sec     712.44 x faster  (avg of 15 runs)
# Grammar::Hooks_01 - find_method wraps Regexes but &(sub)parse are NOT wrapped (incorrect!)                              :     0.156 sec      37.94 x faster  (avg of  2 runs)
# Grammar::Hooks_02 - find_method wraps Regexes but &(sub)parse wrapped in publish_method_cache                           :     0.101 sec      58.49 x faster  (avg of  2 runs)
# Grammar::Tracer_00_standalone - is Metamodel::GrammarHOW / "use Term::ANSICOLOR"                                        :    20.891 sec       3.52 x slower  (avg of  1 runs)
# Grammar::Tracer_00_h00 - is Hooks_00 / "use Term::ANSICOLOR"                                                            :    29.812 sec       5.02 x slower  (avg of  1 runs)

Output completed (1 min 7 sec consumed) - Normal Termination



---------- run perl6 ----------
##### 2014-09-16T13:33:39+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Hooks_00:                              32.781 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa Grammar:           0.026 sec    1260.81 x FASTER :D  (avg'd 15 runs)
# Hooks_01:                               0.438 sec      74.93 x FASTER :D  (avg'd  2 runs)
# Hooks_02:                               0.383 sec      85.59 x FASTER :D  (avg'd  2 runs)
# Tracer_00_standalone:                  85.765 sec       2.62 x slower :(  (avg'd  1 runs)
# Tracer_00_h00:                         99.641 sec       3.04 x slower :(  (avg'd  1 runs)
# Tracer_00_h01:                         92.563 sec       2.82 x slower :(  (avg'd  1 runs)
# Tracer_01_standalone:                   1.203 sec      27.25 x FASTER :D  (avg'd  1 runs)
# Tracer_01_h00:                         42.704 sec       1.30 x slower :(  (avg'd  1 runs)
# Tracer_01_h01:                          1.563 sec      20.97 x FASTER :D  (avg'd  1 runs)



##### 2014-09-16T14:14:48+0200 / rakudo 2014.03.01 on parrot / MSWin32
# Hooks_00:                              37.672 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa Grammar:           0.043 sec     881.56 x FASTER :D  (avg'd 15 runs)
# Hooks_01:                               0.391 sec      96.47 x FASTER :D  (avg'd  2 runs)
# Hooks_02:                               0.398 sec      94.53 x FASTER :D  (avg'd  2 runs)
# Tracer_00_standalone:                  84.859 sec       2.25 x slower :(  (avg'd  1 runs)
# Tracer_00_h00:                        101.110 sec       2.68 x slower :(  (avg'd  1 runs)
# Tracer_00_h01:                         93.063 sec       2.47 x slower :(  (avg'd  1 runs)
# Tracer_00_h02:                         98.500 sec       2.61 x slower :(  (avg'd  1 runs)
# Tracer_01_standalone:                   1.500 sec      25.11 x FASTER :D  (avg'd  1 runs)
# Tracer_01_h00:                         66.235 sec       1.76 x slower :(  (avg'd  1 runs)
# Tracer_01_h01:                          1.266 sec      29.76 x FASTER :D  (avg'd  1 runs)
# Tracer_01_h02:                          1.453 sec      25.93 x FASTER :D  (avg'd  1 runs)



##### 2014-09-17T14:12:44+0200 / rakudo 2014.03.01 on parrot / MSWin32
```
# Hooks_00:                              33.266 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa Grammar:           0.026 sec    1279.46 x FASTER :D  (avg'd 15 runs)
# Hooks_01:                               0.594 sec      56.02 x FASTER :D  (avg'd  5 runs)
# Hooks_02:                               0.612 sec      54.32 x FASTER :D  (avg'd  5 runs)
# Hooks_03:                               0.128 sec     259.69 x FASTER :D  (avg'd 10 runs)
# Tracer_00_standalone:                  86.469 sec       2.60 x slower :(  (avg'd  1 runs)
# Tracer_00_h00:                        102.031 sec       3.07 x slower :(  (avg'd  1 runs)
# Tracer_00_h01:                         94.203 sec       2.83 x slower :(  (avg'd  1 runs)
# Tracer_00_h02:                        102.312 sec       3.08 x slower :(  (avg'd  1 runs)
# Tracer_00_h03:                         77.593 sec       2.33 x slower :(  (avg'd  1 runs)
# Tracer_01_standalone:                   1.508 sec      22.06 x FASTER :D  (avg'd  2 runs)
# Tracer_01_h00:                         25.328 sec       1.31 x FASTER :D  (avg'd  1 runs)
# Tracer_01_h01:                          1.718 sec      19.36 x FASTER :D  (avg'd  1 runs)
# Tracer_01_h02:                          1.508 sec      22.06 x FASTER :D  (avg'd  2 runs)
# Tracer_01_h03:                          0.953 sec      34.89 x FASTER :D  (avg'd  2 runs)

```
----
###### Legend:
  * Tasks
    * **Rx**: `Grammar::Example::RxSimple`: basic regex declarations, eg `rule TOP { ^ <foo>* $ }`; able to parse its own body (!)
  * Exercises
    * **Hooks_00:** `find_method` wraps Regexes plus `&(sub)parse` - both freshly on each call!
    * **bare RxSimple isa Grammar:** without any `use Grammar::*`
    * **Hooks_01:** !INCORRECT! `find_method` wraps Regexes freshly on each call but `&(sub)parse` are NOT wrapped
    * **Hooks_02:** `find_method` wraps Regexes freshly on each call but `&(sub)parse` wrapped in `publish_method_cache`
    * **Hooks_03:** Regexes and `&(sub)parse` wrapped only once each, `find_method` NOT overridden but method cache still disabled
    * **Tracer_00_standalone:** !INCORRECT! as it was: with `use Term::ANSICOLOR` and *like* `Hooks_01` but does all on itself (directly inherits `Metamodel::GrammarHOW`, no `onRegexEnter`... )
    * **Tracer_00_h00:** `is Hooks_00` / `use Term::ANSICOLOR`
    * **Tracer_00_h01:** `is Hooks_01` / `use Term::ANSICOLOR`
    * **Tracer_00_h02:** `is Hooks_02` / `use Term::ANSICOLOR`
    * **Tracer_00_h03:** `is Hooks_03` / `use Term::ANSICOLOR`
    * **Tracer_01_standalone:** !INCORRECT! as it was but NO `Term::ANSICOLOR` and *like* `Hooks_01` but does all on itself (directly inherits `Metamodel::GrammarHOW`, no `onRegexEnter`... )
    * **Tracer_01_h00:** `is Hooks_00` / NO `Term::ANSICOLOR`
    * **Tracer_01_h01:** `is Hooks_01` / NO `Term::ANSICOLOR`
    * **Tracer_01_h02:** `is Hooks_02` / NO `Term::ANSICOLOR`
    * **Tracer_01_h03:** `is Hooks_03` / NO `Term::ANSICOLOR`



##### 2014-09-22T16:15:22+0200 / rakudo 2014.03.01 on parrot / MSWin32 / scale: 2
```
# RxSimple / Hooks_00:                   21.187 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa B isa Grammar:     0.022 sec     971.87 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_01:                    0.266 sec      79.77 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_02:                    0.259 sec      81.68 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_03:                    0.114 sec     185.69 x FASTER :D  (avg'd 10 runs)
# RxSimple / Tracer_00_standalone:       52.485 sec       2.48 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h00:              63.157 sec       2.98 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h01:              54.922 sec       2.59 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h02:              57.719 sec       2.72 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h03:              59.750 sec       2.82 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_standalone:        0.813 sec      26.08 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h00:              29.375 sec       1.39 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_h01:               1.234 sec      17.17 x FASTER :D  (avg'd  1 runs)
# RxSimple / Tracer_01_h02:               0.828 sec      25.59 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h03:               0.625 sec      33.90 x FASTER :D  (avg'd  2 runs)



##### 2014-09-22T16:24:14+0200 / rakudo 2014.03.01 on parrot / MSWin32 / scale: 4
```
# RxSimple / Hooks_00:                   32.985 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa B isa Grammar:     0.053 sec     620.02 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_01:                    0.419 sec      78.80 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_02:                    0.422 sec      78.20 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_03:                    0.178 sec     185.20 x FASTER :D  (avg'd 10 runs)
# RxSimple / Tracer_00_standalone:       86.406 sec       2.62 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h00:              99.281 sec       3.01 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h01:              95.109 sec       2.88 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h02:             102.156 sec       3.10 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h03:              94.765 sec       2.87 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_standalone:        1.406 sec      23.45 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h00:              27.547 sec       1.20 x FASTER :D  (avg'd  1 runs)
# RxSimple / Tracer_01_h01:               1.516 sec      21.76 x FASTER :D  (avg'd  1 runs)
# RxSimple / Tracer_01_h02:               1.367 sec      24.12 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h03:               1.109 sec      29.73 x FASTER :D  (avg'd  2 runs)




##### 2014-09-22T16:51:01+0200 / rakudo 2014.03.01 on parrot / MSWin32 / scale: 1
```
# RxSimple / Hooks_00:                    2.219 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa B isa Grammar:     0.006 sec     354.09 x FASTER :D  (avg'd 15 runs)
# RxSimple / Hooks_01:                    0.091 sec      24.49 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_02:                    0.091 sec      24.49 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_03:                    0.030 sec      74.97 x FASTER :D  (avg'd 10 runs)
# RxSimple / Tracer_00_standalone:       13.469 sec       6.07 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h00:              18.532 sec       8.35 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h01:              14.234 sec       6.41 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h02:              16.125 sec       7.27 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h03:              15.563 sec       7.01 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_standalone:        0.172 sec      12.90 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h00:               3.954 sec       1.78 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_h01:               0.172 sec      12.90 x FASTER :D  (avg'd  1 runs)
# RxSimple / Tracer_01_h02:               0.250 sec       8.88 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h03:               0.133 sec      16.68 x FASTER :D  (avg'd  2 runs)



##### 2014-09-22T16:54:20+0200 / rakudo 2014.03.01 on parrot / MSWin32 / scale: 5
```
# RxSimple / Hooks_00:                   42.234 sec       1.00 x reference  (avg'd  1 runs)
# bare RxSimple isa B isa Grammar:     0.036 sec    1158.15 x FASTER :D  (avg'd 15 runs)
# RxSimple / Hooks_01:                    0.584 sec      72.27 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_02:                    0.566 sec      74.67 x FASTER :D  (avg'd  5 runs)
# RxSimple / Hooks_03:                    0.241 sec     175.46 x FASTER :D  (avg'd 10 runs)
# RxSimple / Tracer_00_standalone:      117.953 sec       2.79 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h00:             144.234 sec       3.42 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h01:             139.016 sec       3.29 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h02:             136.610 sec       3.23 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_00_h03:             144.625 sec       3.42 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_standalone:        1.883 sec      22.43 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h00:              88.906 sec       2.11 x slower :(  (avg'd  1 runs)
# RxSimple / Tracer_01_h01:               3.219 sec      13.12 x FASTER :D  (avg'd  1 runs)
# RxSimple / Tracer_01_h02:               2.016 sec      20.95 x FASTER :D  (avg'd  2 runs)
# RxSimple / Tracer_01_h03:               1.695 sec      24.92 x FASTER :D  (avg'd  2 runs)




ENDOFHEREDOC
