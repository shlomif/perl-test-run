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
use File::Spec;

my $Curdir = File::Spec->curdir;
my $SAMPLE_TESTS = $ENV{PERL_CORE}
                    ? File::Spec->catdir($Curdir, 'lib', 'sample-tests')
                    : File::Spec->catdir($Curdir, 't',   'sample-tests');


use Test::More tests => 1;;

my $IsMacPerl = $^O eq 'MacOS';
my $IsVMS     = $^O eq 'VMS';

# VMS uses native, not POSIX, exit codes.
# MacPerl's exit codes are broken.
my $die_estat = $IsVMS     ? 44 : 
                $IsMacPerl ? 0  :
                             1;

use Test::Run::Obj;


open ALTOUT, ">", "altout.txt";
open SAVEOUT, ">&STDOUT";
open STDOUT, ">&ALTOUT";
    
my $tester = Test::Run::Obj->new(
    test_files => ["t/sample-tests/simple_fail"]
    );
eval {
$tester->runtests();
};

open STDOUT, ">&SAVEOUT";
close(SAVEOUT);
close(ALTOUT);
my $text = do { local $/; open I, "<", "altout.txt"; <I>};
my $right_text = <<"EOF";
t/sample-tests/simple_fail...FAILED tests 2, 5
	Failed 2/5 tests, 60.00% okay
Failed Test                Stat Wstat Total Fail  Failed  List of Failed
-------------------------------------------------------------------------------
t/sample-tests/simple_fail                5    2  40.00%  2 5
EOF
# TEST
is ($text, $right_text, "Testing for the right failure text");

