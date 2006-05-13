#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::ColorSummary;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

package main;

use Test::More tests => 6;

use Term::ANSIColor;

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/several-oks.t"
        ],
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $color = color("bold blue");

    # TEST
    ok (($text =~ m/\Q${color}\EAll tests successful\./), "'All tests successful.' string as is");
}

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-fail.t",
        ],
        );

    eval {
    $tester->runtests();
    };

    my $err = $@;

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);

    my $err_text = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};

    my $color = color("bold red");

    # TEST
    ok (($err_text =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
        qq{Found colored "Failed 1/1" string});

    # TEST
    ok ($err, qq{Exited with an exception});
}

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/several-oks.t"
        ],
        summary_color_success => "green",
        summary_color_failure => "yellow",
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $color = color("green");

    # TEST
    ok (($text =~ m/\Q${color}\EAll tests successful\./), 
        "Text is colored green on explicity SummaryColor_success");
}

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-fail.t",
        ],
        summary_color_success => "green",
        summary_color_failure => "yellow",
        );

    eval {
    $tester->runtests();
    };
    my $err = $@;

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);

    my $err_text = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};

    my $color = color("yellow");

    # TEST
    ok (($err_text =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
        qq{Found colored "Failed 1/1" string with user-specified color});
    # TEST
    ok ($err, qq{Exited with an exception});
}
