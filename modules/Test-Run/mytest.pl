# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

#!/usr/bin/perl

use Test::Run::Obj;

my $tester = 
    Test::Run::Obj->new(
        {
            'test_files' => ["t/sample-tests/head_fail"],
            # 'test_files' => ["t/sample-tests/head_end"],
            # 'Verbose' => 1,
            # 'Debug' => 1,
        }
    );
$tester->runtests();

