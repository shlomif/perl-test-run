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

use Test::Shlomif::Harness::Obj;
use Test::More tests => 1;
use Dev::Null;

push @INC, 'we_added_this_lib';

tie *NULL, 'Dev::Null' or die $!;
select NULL;
my($tot, $failed) = Test::Shlomif::Harness::Obj::_run_all_tests(
    $ENV{PERL_CORE}
    ? 'lib/sample-tests/inc_taint'
    : 't/sample-tests/inc_taint'
);
select STDOUT;

# TEST
ok( Test::Shlomif::Harness::Obj::_all_ok($tot), 'tests with taint on preserve @INC' );
