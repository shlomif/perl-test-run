#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::FailSummaryComponents;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::FailSummaryComponents Test::Run::Obj));

package main;

use Test::More tests => 2;

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
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
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

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $expected = qq{Failed 1/2 test scripts, 50.00% okay. 1/2 subtests failed, 50.00% okay.\n};

    # TEST
    is ($err, $expected, "Failed string is right.");
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
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
        ],
        'failsumm_remove_test_scripts_number' => 1,
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

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $expected = qq{Failed test scripts, 50.00% okay. 1/2 subtests failed, 50.00% okay.\n};

    # TEST
    is ($err, $expected, "failsumm_remove_test_scripts_number");
}

