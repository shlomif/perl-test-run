#!/usr/bin/perl

use Test::Shlomif::Harness::Obj;

my $tester = 
    Test::Shlomif::Harness::Obj->new(
        # 'test_files' => ["t/sample-tests/simple_fail"]
        'test_files' => ["t/sample-tests/head_end"]
    );
$tester->runtests();

