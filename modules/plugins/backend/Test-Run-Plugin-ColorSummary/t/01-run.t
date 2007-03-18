#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::ColorSummary;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

package main;

use Test::More tests => 4;

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

    my $color = color("bold blue");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\EAll tests successful\./), "'All tests successful.' string as is");
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-fail.t",
            ],
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("bold red");

    # TEST
    ok (($trap->die() =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
        qq{Found colored "Failed 1/1" string});
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
            summary_color_success => "green",
            summary_color_failure => "yellow",
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("green");

    # TEST
    ok (($trap->stdout() =~ m/\Q${color}\EAll tests successful\./), 
        "Text is colored green on explicity SummaryColor_success");
}

{
    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-fail.t",
            ],
            summary_color_success => "green",
            summary_color_failure => "yellow",
        }
        );

    trap {
    $tester->runtests();
    };

    my $color = color("yellow");

    # TEST
    ok (($trap->die() =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
        qq{Found colored "Failed 1/1" string with user-specified color});
}
