#!/usr/bin/perl -w

use strict;

use Test::More tests => 1;
use File::Spec;

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $test_file = File::Spec->catfile("t", "sample-tests", "one-ok.t");
{
    local $ENV{'TEST_HARNESS_DRIVER'};
    local $ENV{'PERL5LIB'} = $lib;
    
    {
        my $results = qx{$runprove $test_file};
        
        # TEST
        ok (($results =~ m/All tests successful\./), 
            "Good results from runprove");
    }
}
1;

