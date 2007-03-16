#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

package MyTestRun;

use base 'Test::Run::Plugin::CollectStats';
use base 'Test::Run::Obj';

package main;

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/simple",
                "t/sample-tests/todo",
            ],
        }
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    # TEST
    is ($tester->get_num_collected_tests(),
        2,
        "Length of the recorded test files data"
    );

    # TEST
    is ($tester->find_test_file_idx_by_filename("t/sample-tests/simple"),
        0,
        "t/sample-test/simple is the 0th element"
    );

    # TEST
    is ($tester->find_test_file_idx_by_filename("t/sample-tests/todo"),
        1,
        "t/sample-test/todo is the 1th element"
    );

    # TEST
    is ($tester->get_recorded_test_file_data(0)->summary_object->ok(),
        5,
        "simple 'ok' count"
    );
}

