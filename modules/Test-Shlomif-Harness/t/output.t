#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 18;

use Test::Run::Obj;
use Test::Run::Trap::Obj;

{
    my $got = Test::Run::Trap::Obj->trap_run({
            args => [test_files => ["t/sample-tests/simple"]]
        });

    # TEST
    $got->field_like("stdout", qr/All tests successful\./, 
        "simple - 'All tests successful.' string as is"
    );

    # TEST
    $got->field_like("stdout", 
        qr/^Files=\d+, Tests=\d+,  [^\n]*wallclock secs/m,
        "simple - Final Stats line matches format."
    );
}

# Run several tests.
{
    my $got = Test::Run::Trap::Obj->trap_run({
        args =>
        [
            test_files =>         
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
        ]
    });

    # TEST
    $got->field_like("stdout", qr/All tests successful/, 
        "simple+head_end+todo - 'All tests successful' (without the period) string as is"
    );
}

# Skipped sub-tests
{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/skip",
            ],
        ]
    });

    # TEST
    $got->field_like(
        "stdout",
        qr/All tests successful, 1 subtest skipped\./,
        "1 subtest skipped with a comma afterwards."
    );
}

# Run several tests with debug.
{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
            Debug => 1,
        ]
    });
    
    # TEST
    $got->field_like("stdout", qr/All tests successful/, 
        "In debug - 'All tests successful' (without the period) string as is");
    # TEST
    $got->field_like("stdout", qr/^# PERL5LIB=/m, 
        "In debug - Matched a Debug diagnostics");
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/bailout", 
            ],
        ]
    });
    
    my $match = 'FAILED--Further testing stopped: GERONIMMMOOOOOO!!!';
    # TEST
    $got->field_like("die", ('/' . quotemeta($match) . '/'), 
        "Bailout - Matched the bailout error."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/skip", 
            ],
        ]
    });
    
    # TEST
    $got->field_like("stdout", 
        qr{t/sample-tests/skip\.+ok\n {8}1/5 skipped: rain delay\n},
        "skip - Matching the skipped line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/todo", 
            ],
        ]
    });
    
    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/todo\.+ok\n {8}1/5 unexpectedly succeeded\n},
        "Todo only - Matching the bonus line."
    );


    # TEST
    $got->field_like("stdout",
        qr{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED).\E\n}sm,
        "Todo only - Testing for a good summary line"
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/skip_and_todo", 
            ],
        ]
    });
    
    # TEST
    $got->field_like("stdout", 
        qr{t/sample-tests/skip_and_todo\.+ok\n {8}1/6 skipped: rain delay, 1/6 unexpectedly succeeded\n},
        "skip_and_todo - Matching the bonus+skip line."
    );

    # TEST
    $got->field_like("stdout", 
        qr{^\QAll tests successful (1 subtest UNEXPECTEDLY SUCCEEDED), 1 subtest skipped.\E\n}m,
        "skip_and_todo - Testing for a good summary line"
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/skipall", 
            ],
        ]
    });
    
    # TEST
    $got->field_like(
        "stdout",
        qr{t/sample-tests/skipall\.+skipped\n {8}all skipped: rope\n},
        "skipall - Matching the all skipped with the reason."
        );
    # TEST
    $got->field_like(
        "stdout",
        qr{^All tests successful, 1 test skipped\.\n}m,
        "skipall - Matching the skipall summary line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/simple_fail", 
            ],
        ]
    });
    
    # TEST
    $got->field_like("stdout",
        qr{t/sample-tests/simple_fail\.+FAILED tests 2, 5\n\tFailed 2/5 tests, 60.00% okay},
        "simple_fail - Matching the FAILED test report"
        );
    # TEST
    $got->field_like("die", 
        qr{^Failed 1/1 test scripts, 0.00% okay\. 2/5 subtests failed, 60\.00% okay\.$}m,
        "simple_fail - Matching the Failed summary line."
    );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/invalid-perl", 
            ],
        ]
    });
    
    # TEST
    $got->field_like("die",
        qr{FAILED--1 test script could be run, alas--no output ever seen},
        "Checking for the string in \"no output ever seen\""
        );
}

{
    my $got = Test::Run::Trap::Obj->trap_run({args =>
        [
            test_files => 
            [
                "t/sample-tests/head_fail", 
            ],
        ]
    });
    
    # TEST
    $got->field_is_deeply("warn", [],
        "Checking for no warnings on failure"
        );
}

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

