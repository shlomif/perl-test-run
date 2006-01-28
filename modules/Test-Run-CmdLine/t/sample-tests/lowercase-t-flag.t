#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;

my $num_warnings = 0;
{
    local $SIG{__WARN__} = sub { $num_warnings++; };
    eval ("#" . substr($ENV{'PATH'}, 0, 0));
}

# TEST
is ($num_warnings, 1, "The -t flag was passed.");
