#!/usr/bin/perl

# The most minimal Test::Run (Core) program possible.
# run as perl Test.pl @FILES.

use strict;
use warnings;

use Test::Run::Obj;

my $harness = Test::Run::Obj->new({
        test_files => [@ARGV]
    }
);

$harness->runtests();
