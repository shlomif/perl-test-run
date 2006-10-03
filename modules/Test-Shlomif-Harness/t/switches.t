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

use Test::More tests => 3;

use File::Spec;

use Test::Run::Obj;

my $switches = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib1");
my $switches_lib2 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib2");
# Test Switches()
{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello"],
            Switches => $switches,
        }   
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    # TEST
    ok (($text =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Test Switches_Env()
{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello"],
            Switches_Env => $switches,
        }
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    # TEST
    ok (($text =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Test both Switches() and Switches_Env().
{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello-and-myfoo"],
            Switches => $switches_lib2,
            Switches_Env => $switches,
        }
    );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    # TEST
    ok (($text =~ m/All tests successful\./), "'All tests successful.' string as is");
}
