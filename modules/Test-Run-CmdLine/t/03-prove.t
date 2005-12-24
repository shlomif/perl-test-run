#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;
use File::Spec;
use File::Path;
use Config;

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $leaked_files_dir = File::Spec->catfile($sample_tests_dir, "leaked-files-dir");
my $leaked_file = File::Spec->catfile($leaked_files_dir, "hello.txt");
my $leak_test_file = File::Spec->catfile($sample_tests_dir, "leak-file.t");
{
    local %ENV = %ENV;
    local $ENV{'TEST_HARNESS_DRIVER'};
    local $ENV{'PERL5LIB'} = $lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
    
    delete($ENV{'HARNESS_FILELEAK_IN_DIR'});
    delete($ENV{'HARNESS_VERBOSE'});
    {
        my $results = qx{$runprove $test_file};
        
        # TEST
        ok (($results =~ m/All tests successful\./), 
            "Good results from runprove");
    }

    {
        mkdir($leaked_files_dir, 0777);
        open O, ">", $leaked_file;
        print O "This is the file hello.txt";
        close(O);

        local $ENV{'HARNESS_FILELEAK_IN_DIR'} = $leaked_files_dir;

        my $results = qx{$runprove $leak_test_file $test_file};

        # TEST
        ok (($results =~ m/\nLEAKED FILES: new-file.txt\n/),
            "Checking for files that were leaked");
        rmtree([$leaked_files_dir], 0, 0);
    }

    {
        local $ENV{'HARNESS_VERBOSE'} = 1;
        my $results = qx{$runprove $test_file};
        
        # TEST
        ok (($results =~ m/^ok 1/m),
            "Testing is 'Verbose' is HARNESS_VERBOSE is 1.");
    }
    {
        # This is a control experiment.
        local $ENV{'HARNESS_VERBOSE'} = 0;
        my $results = qx{$runprove $test_file};
        
        # TEST
        ok (($results !~ m/^ok 1/m),
            "Testing is not 'Verbose' if HARNESS_VERBOSE is 0.");
    }
    {
        my $results = qx{$runprove -v $test_file};
        
        # TEST
        ok (($results =~ m/^ok 1/m),
            "Testing is 'Verbose' with the '-v' flag.");
    }
}
1;

