#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::ColorSummary;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

package main;

use Test::More tests => 1;

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

    # TEST
    ok (($text =~ m/All tests successful\./), "'All tests successful.' string as is");
}

