#!/usr/bin/perl -w

BEGIN {
    if( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 5;

use Test::Run::Obj;

sub trap_output
{
    my $args = shift;

    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = Test::Run::Obj->new(
        @$args,
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    return
    {
        'stdout' => $text,
    }
}

{
    my $got = trap_output([test_files => ["t/sample-tests/simple"]]);
    # TEST
    ok (($got->{stdout} =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Run several tests.
{
    my $got = trap_output(
        [
            test_files =>         
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
        ]
    );

    # TEST
    ok (($got->{stdout} =~ m/All tests successful/), "'All tests successful' (without the period) string as is");
}

# Skipped sub-tests
{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/skip",
            ],
        ]
    );

    # TEST
    ok (($got->{stdout} =~ m/All tests successful, 1 subtest skipped\./), "1 subtest skipped with a comma afterwards.");
}

# Run several tests with debug.
{
    my $got = trap_output(
        [
            test_files => 
            [
                "t/sample-tests/simple", 
                "t/sample-tests/head_end",
                "t/sample-tests/todo",
            ],
            Debug => 1,
        ]
    );
    
    my $text = $got->{stdout};
    # TEST
    ok (($text =~ m/All tests successful/), "'All tests successful' (without the period) string as is");
    # TEST
    ok (($text =~ m/^# PERL5LIB=/m), "Matched a Debug diagnostics");
}
