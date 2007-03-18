#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 15;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use Test::Run::Obj;

sub trap_output
{
    my $args = shift;

    my $tester = Test::Run::Obj->new(
        {@$args},
        );

    trap { $tester->runtests(); };

    return
    {
        'stdout' => $trap->stdout(),
        'error' => $trap->die(),
    }
}

{
    my $got = trap_output([test_files => ["t/sample-tests/simple"]]);
    # TEST
    ok (($got->{stdout} =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Run several tests.
{
    my $got = trap_output(
        [
            test_files =>         
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
        ]
    );

    # TEST
    ok (($got->{stdout} =~ m/All tests successful/), "'All tests successful' (without the period) string as is");
}

# Skipped sub-tests
{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/skip",
            ],
        ]
    );

    # TEST
    ok (($got->{stdout} =~ m/All tests successful, 1 subtest skipped\./), "1 subtest skipped with a comma afterwards.");
}

# Run several tests with debug.
{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
            Debug => 1,
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok (($text =~ m/All tests successful/), "'All tests successful' (without the period) string as is");
    # TEST
    ok (($text =~ m/^# PERL5LIB=/m), "Matched a Debug diagnostics");
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/bailout", 
            ],
        ]
    );
    
    my $error = $got->{error};
    my $match = 'FAILED--Further testing stopped: GERONIMMMOOOOOO!!!';
    # TEST
    like ("$error", ('/' . quotemeta($match) . '/'), 
        "Matched the bailout error."
    );
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/skip", 
            ],
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok ($text =~ m{t/sample-tests/skip\.+ok\n {8}1/5 skipped: rain delay\n},
        "Matching the skipped line.");
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/todo", 
            ],
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok ($text =~ m{t/sample-tests/todo\.+ok\n {8}1/5 unexpectedly succeeded\n},
        "Matching the bonus line.");

    # TEST
    ok ($text =~ m{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED).\E$}m,
        "Testing for a good summary line");
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/skip_and_todo", 
            ],
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok (scalar($text =~ m{t/sample-tests/skip_and_todo\.+ok\n {8}1/6 skipped: rain delay, 1/6 unexpectedly succeeded\n}),
        "Matching the bonus+skip line.");
    # TEST
    ok (scalar($text =~ m{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED), 1 subtest skipped.\E$}m),
        "Testing for a good summary line");
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/skipall", 
            ],
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok (scalar($text =~ m{t/sample-tests/skipall\.+skipped\n {8}all skipped: rope\n}),
        "Matching the all skipped with the reason."
        );
    # TEST
    ok (scalar($text =~ m{^All tests successful, 1 test skipped\.$}m),
        "Matching the skipall summary line.");
}

{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/simple_fail", 
            ],
        ]
    );
    
    my $text = $got->{stdout};
    my $error = $got->{error};

    # TEST
    ok (scalar($text =~ m{t/sample-tests/simple_fail\.+FAILED tests 2, 5\n\tFailed 2/5 tests, 60.00% okay}),
        "Matching the FAILED test report"
        );
    # TEST
    ok (scalar("$error" =~ m{^Failed 1/1 test scripts, 0.00% okay\. 2/5 subtests failed, 60\.00% okay\.$}m),
        "Matching the Failed summary line.");
}
