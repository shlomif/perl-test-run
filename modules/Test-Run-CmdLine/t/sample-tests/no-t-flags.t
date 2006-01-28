#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

sub is_tainted 
{
    return ! eval { eval("#" . substr(join("", @_), 0, 0)); 1 };
}

# TEST
ok (!is_tainted($ENV{'PATH'}), "\$ENV{PATH} is not tainted.");

