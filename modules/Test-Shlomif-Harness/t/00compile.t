#!/usr/bin/perl -w

BEGIN {
    if($ENV{PERL_CORE}) {
        chdir 't';
        @INC = '../lib';
    }
    else {
        unshift @INC, 't/lib';
    }
}

use Test::More tests => 1;

# TEST
BEGIN { use_ok 'Test::Shlomif::Harness::Obj' }
BEGIN { diag( "Testing Test::Shlomif::Harness::Obj $Test::Shlomif::Harness::Obj::VERSION under Perl $] and Test::More $Test::More::VERSION" ) unless $ENV{PERL_CORE}}

