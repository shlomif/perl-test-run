#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

package MyTestRun;

use base 'Test::Run::Plugin::ColorFileVerdicts';
use base 'Test::Run::Obj';

package main;

use Term::ANSIColor;

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("green");
    my $reset = color("reset");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\Eok\Q${reset}\E/),
        "ok is colored green");
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
            individual_test_file_verdict_colors => 
            {
                success => "yellow",
                failure => "blue",
            },
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("yellow");
    my $reset = color("reset");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\Eok\Q${reset}\E/),
        "ok is colored yellow per the explicit setup");
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/one-fail-exit-0.t"
            ],
            individual_test_file_verdict_colors => 
            {
                success => "yellow",
                failure => "blue",
            },
        }
        );

    trap {
    $tester->runtests();
    };
    
    my $color = color("blue");
    my $reset = color("reset");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\EFAILED test 1\Q${reset}\E/),
        "FAILED test 1 colored.");
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/one-fail.t"
            ],
            individual_test_file_verdict_colors => 
            {
                success => "yellow",
                failure => "blue",
                dubious => "magenta",
            },
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("magenta");
    my $reset = color("reset");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\Edubious\Q${reset}\E/),
        "dubious colored.");
}
