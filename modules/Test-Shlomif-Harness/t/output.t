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

use Test::More tests => 1;

use Test::Run::Obj;

open ALTOUT, ">", "altout.txt";
open SAVEOUT, ">&STDOUT";
open STDOUT, ">&ALTOUT";

my $tester = Test::Run::Obj->new(
    test_files => ["t/sample-tests/simple"],
    );

$tester->runtests();

open STDOUT, ">&SAVEOUT";
close(SAVEOUT);
close(ALTOUT);

my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

# TEST
ok (($text =~ m/All tests successful\./), "'All tests successful.' string as is");

