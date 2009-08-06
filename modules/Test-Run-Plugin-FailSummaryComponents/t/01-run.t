#!/usr/bin/perl

use strict;
use warnings;

use Test::Run::Obj;
use Test::Run::Plugin::FailSummaryComponents;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );
package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::FailSummaryComponents Test::Run::Obj));

package main;

use Test::More tests => 4;

sub tester
{
    my $args = shift;

    my $tester = MyTestRun->new(
        $args,
        );

    trap {
    $tester->runtests();
    };

    return 
    {
        'stdout' => $trap->stdout(),
        'stderr' => $trap->stderr(),
        'exception' => $trap->die(),
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
