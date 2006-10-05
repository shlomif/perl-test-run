#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::FailSummaryComponents;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::FailSummaryComponents Test::Run::Obj));

package main;

use Test::More tests => 4;

sub tester
{
    my $args = shift;

    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";

    my $tester = MyTestRun->new(
        $args,
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
    my $stderr = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};   

    return 
    {
        'stdout' => $text,
        'stderr' => $stderr,
        'exception' => $err,
    };
}

{
    my $results = tester({test_files =>
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
        ]});

    my $err = $results->{exception};

    my $expected = qq{Failed 1/2 test scripts, 50.00% okay. 1/2 subtests failed, 50.00% okay.\n};

    # TEST
    is ("$err", $expected, "Failed string is right.");
}

{
    my $results = tester({test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
        ],
        'failsumm_remove_test_scripts_number' => 1,
        });

    my $err = $results->{exception};

    my $expected = qq{Failed test scripts, 50.00% okay. 1/2 subtests failed, 50.00% okay.\n};

    # TEST
    is ("$err", $expected, "failsumm_remove_test_scripts_number");
}

{
    my $results = tester({test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
        ],
        failsumm_remove_test_scripts_percent => 1,
    });

    my $err = $results->{exception};

    my $expected = qq{Failed 1/2 test scripts. 1/2 subtests failed, 50.00% okay.\n};

    # TEST
    is ("$err", $expected, "failsumm_remove_test_scripts_percent => 1 behavior");
}

{
    my $results = tester({
        test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/one-fail.t"
        ],
        failsumm_remove_subtests_percent => 1,
    });

    my $err = $results->{exception};

    my $expected = qq{Failed 1/2 test scripts, 50.00% okay. 1/2 subtests failed.\n};

    # TEST
    is ("$err", $expected, "failsumm_remove_substests_percent => 1 behavior");
}
