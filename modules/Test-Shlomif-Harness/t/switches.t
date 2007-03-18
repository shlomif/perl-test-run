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

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use File::Spec;

use Test::Run::Obj;

my $switches = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib1");
my $switches_lib2 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib2");
# Test Switches()
{
    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello"],
            Switches => $switches,
        }   
        );

    trap {
    $tester->runtests();
    };

    # TEST
    ok (($trap->stdout() =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Test Switches_Env()
{
    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello"],
            Switches_Env => $switches,
        }
        );

    trap {
        $tester->runtests();
    };

    # TEST
    ok (($trap->stdout() =~ m/All tests successful\./), "'All tests successful.' string as is");
}

# Test both Switches() and Switches_Env().
{
    my $tester = Test::Run::Obj->new(
        {
            test_files => ["t/sample-tests/with-myhello-and-myfoo"],
            Switches => $switches_lib2,
            Switches_Env => $switches,
        }
    );

    trap {
    $tester->runtests();
    };

    # TEST
    ok (($trap->stdout() =~ m/All tests successful\./), "'All tests successful.' string as is");
}
