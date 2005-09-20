#!/usr/bin/perl -Tw

BEGIN {
    if ( $ENV{PERL_CORE} ) {
        chdir 't';
        @INC = ('../lib', 'lib');
    }
    else {
        unshift @INC, 't/lib';
    }
}

use strict;

use Test::More tests => 2;

BEGIN {
    use_ok( 'Test::Shlomif::Harness::Obj' );
}

my $strap = Test::Shlomif::Harness::Obj->strap;
isa_ok( $strap, 'Test::Shlomif::Harness::Straps' );
