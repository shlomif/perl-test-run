#!/usr/bin/perl

use strict;
use warnings;

package MyTestRun;

use base 'Test::Run::Plugin::ColorFileVerdicts';
use base 'Test::Run::Obj';

package main;

use Test::More tests => 2;

use Term::ANSIColor;

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            ],
        }
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $color = color("green");
    my $reset = color("reset");

    # TEST
    ok (($text =~ m/\Q${color}\Eok\Q${reset}\E/),
        "ok is colored green");
}

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

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

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $color = color("yellow");
    my $reset = color("reset");

    # TEST
    ok (($text =~ m/\Q${color}\Eok\Q${reset}\E/),
        "ok is colored yellow per the explicit setup");
}

