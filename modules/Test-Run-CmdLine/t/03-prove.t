#!/usr/bin/perl -w

use strict;

use Test::More tests => 21;
use File::Spec;
use File::Path;
use Config;

sub trap
{
    my $cmd = shift;
    local (*SAVEERR, *ALTERR);
    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";
    my $output = qx/$cmd/;
    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);
    my $error = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};
    return wantarray() ? ($output, $error) : $output;
}

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $with_myhello_file = File::Spec->catfile($sample_tests_dir, "with-myhello");
my $with_myhello_and_myfoo_file = File::Spec->catfile($sample_tests_dir, "with-myhello-and-myfoo");
my $simple_fail_file = File::Spec->catfile($sample_tests_dir, "simple_fail.t");
my $leaked_files_dir = File::Spec->catfile($sample_tests_dir, "leaked-files-dir");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");
my $leaked_file = File::Spec->catfile($leaked_files_dir, "hello.txt");
my $leak_test_file = File::Spec->catfile($sample_tests_dir, "leak-file.t");
my $switches_lib1 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib1");
my $switches_lib2 = "-I" . File::Spec->catdir(File::Spec->curdir(), "t", "test-libs", "lib2");

{
    local %ENV = %ENV;
    
    local $ENV{'PERL5LIB'} = $lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
    delete($ENV{'HARNESS_FILELEAK_IN_DIR'});
    delete($ENV{'HARNESS_VERBOSE'});
    delete($ENV{'HARNESS_DEBUG'});
    delete($ENV{'HARNESS_COLUMNS'});
    delete($ENV{'HARNESS_TIMER'});
    delete($ENV{'HARNESS_NOTTY'});
    delete($ENV{'HARNESS_PERL'});
    delete($ENV{'HARNESS_PERL_SWITCHES'});
    delete($ENV{'HARNESS_DRIVER'});
    delete($ENV{'HARNESS_PLUGINS'});
    $ENV{'COLUMNS'} = 80;
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
            "Testing is 'Verbose' if HARNESS_VERBOSE is 1.");
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
    {
        local $ENV{'HARNESS_DEBUG'} = 1;
        my $results = qx{$runprove $test_file};
        
        # TEST
        ok (($results =~ m/# Running:/),
            "Testing is 'Debug' if HARNESS_DEBUG is 1.");
    }
    {
        my $results = qx{$runprove -d $test_file};
        
        # TEST
        ok (($results =~ m/# Running:/),
            "Testing is 'Debug' is the '-d' flag was specified.");
    }
    {
        my $results = trap("$runprove $simple_fail_file");

        # TEST
        ok (($results =~ m/^\-{79}$/m),
            "Testing that simple fail is formatted for 80 columns");
    }
    {
        local $ENV{'COLUMNS'} = 100;
        my $results = trap("$runprove $simple_fail_file");

        # TEST
        ok (($results =~ m/^\-{99}$/m),
            "Testing that simple fail is formatted for 100 columns");
    }
    {
        local $ENV{'HARNESS_COLUMNS'} = 100;
        my $results = trap("$runprove $simple_fail_file");

        # TEST
        ok (($results =~ m/^\-{99}$/m),
            "Testing that simple fail is formatted for 100 columns");
    }
    {
        local %ENV = %ENV;
        # delete ($ENV{'COLUMNS'});
        my $results = trap("$runprove $simple_fail_file");

        # TEST
        ok (($results =~ m/^\-{79}$/m),
            "Testing that Columns defaults to 80");
    }
    {
        local $ENV{'HARNESS_TIMER'} = 1;
        my $results = trap("$runprove $test_file $several_oks_file");
        
        # TEST
        ok (($results =~ m/ok\s+\d+(?:\.\d+)?s$/m),
            "Displays the time if HARNESS_TIMER is 1.");
    }
    {
        my $results = trap("$runprove --timer $test_file $several_oks_file");
        
        # TEST
        ok (($results =~ m/ok\s+\d+(?:\.\d+)?s$/m),
            "Displays the time if --timer was set.");
    }
    {
        my $results = trap("$runprove $test_file $several_oks_file");
        
        # TEST
        ok (($results =~ m/ok$/m),
            "Timer control experiment");
    }
    {
        local $ENV{'HARNESS_NOTTY'} = 1;
        my $results = trap("$runprove $test_file $several_oks_file");
        
        # TEST
        ok (($results =~ m/All tests successful\./), 
            "Good results from HARNESS_NOTTY");
    }
    {
        local $ENV{'HARNESS_PERL'} = $^X;
        my $results = trap("$runprove $test_file $several_oks_file");

        # TEST
        ok (($results =~ m/All tests successful\./),
            "Good results from HARNESS_PERL");
    }
    {
        my $results = trap("$runprove --perl $^X $test_file $several_oks_file");

        # TEST
        ok (($results =~ m/All tests successful\./),
            "Good results with the '--perl' flag");
    }
    {
        local $ENV{'HARNESS_PERL_SWITCHES'} = $switches_lib1;
        my $results = trap("$runprove $with_myhello_file");

        # TEST
        ok (($results =~ m/All tests successful\./),
            "Good results with the '--perl' flag");
    }
    {
        my $results = trap("$runprove $switches_lib1 $with_myhello_file");

        # TEST
        ok (($results =~ m/All tests successful\./),
            "Good results with the '--perl' flag");
    }
    {
        local $ENV{'HARNESS_PERL_SWITCHES'} = $switches_lib2;
        my $results = trap("$runprove $switches_lib1 $with_myhello_and_myfoo_file");

        # TEST
        ok (($results =~ m/All tests successful\./),
            "Good results with the '--perl' flag");
    }
    # Test that it can work around a specified HARNESS_PLUGINS and an
    # unspecified HARNESS_DRIVER.
    {
        local $ENV{'HARNESS_PLUGINS'} = "Super";
        local $ENV{'PERL5LIB'} = $t_dir.$Config{'path_sep'}.$ENV{'PERL5LIB'};
        my $results = trap("$runprove $test_file $several_oks_file");

        # TEST
        like ($results, qr/All tests are super-successful\!/,
            "Good results with the HARNESS_PLUGINS env var alone.");
    }
}
1;

