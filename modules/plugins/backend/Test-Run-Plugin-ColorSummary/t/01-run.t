#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::ColorSummary;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

package main;

use Test::More tests => 2;

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

    $tester->runtests();

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
}
