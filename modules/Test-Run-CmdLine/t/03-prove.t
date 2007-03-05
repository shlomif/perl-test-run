#!/usr/bin/perl -w

use strict;

use Test::More tests => 36;
use File::Spec;
use File::Path;
use Config;
use Cwd;

my $abs_cur = getcwd();
my $alterr_filename = File::Spec->catfile($abs_cur, "alterr.txt");

sub trap
{
    my $cmd = shift;
    local (*SAVEERR, *ALTERR);
    open ALTERR, ">", $alterr_filename;
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";
    my $output = qx/$cmd/;
    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);
    my $error = do { local $/; local *I; open I, "<", $alterr_filename; <I>};
    return wantarray() ? ($output, $error) : $output;
}


my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $t_dir = File::Spec->catfile( File::Spec->curdir, "t" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);
my $runprove = File::Spec->catfile( $blib, "script", "runprove" );
my $abs_runprove = Cwd::abs_path($runprove);
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
my $no_t_flags_file = File::Spec->catfile($sample_tests_dir, "no-t-flags.t");
my $lowercase_t_flag_file = File::Spec->catfile($sample_tests_dir, "lowercase-t-flag.t");
my $uppercase_t_flag_file = File::Spec->catfile($sample_tests_dir, "uppercase-t-flag.t");

{
    local %ENV = %ENV;
    
    local $ENV{'PERL5LIB'} = $abs_lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
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
    delete($ENV{'PROVE_SWITCHES'});
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
    {
        my $results = trap("$runprove --version");

        # TEST
        like ($results, qr/runprove v.*using Test::Run v.*Test::Run::CmdLine v.*Perl v/,
            "Good results for the version string");
    }
    {
        my $results = trap("$runprove $no_t_flags_file");
        
        # TEST
        like ($results, qr/All tests successful\./, 
            "Good results for the absence of the -t flag");
    }
    {
        my $results = trap("$runprove -t $lowercase_t_flag_file");
        
        # TEST
        like ($results, qr/All tests successful\./, 
            "Good results for the presence of the -t flag");
    }
    {
        my $results = trap("$runprove -T $uppercase_t_flag_file");
        
        # TEST
        like ($results, qr/All tests successful\./, 
            "Good results for the presence of the -T flag");
    }
    {
        my $results = trap("$runprove -T $no_t_flags_file");
        
        # TEST
        like ($results, qr/FAILED test/, 
            "Test that requires no taint fails if -T is specified");
    }
    {
        my $results = trap("$runprove $uppercase_t_flag_file");
        
        # TEST
        like ($results, qr/FAILED test/,
            "Good results for the presence of the -T flag");
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-blib"));

        my $results = trap("$abs_runprove --blib " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"));
        
        # TEST
        like ($results, qr/All tests successful\./,
            "Good results for the presence of the --blib flag");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-blib"));

        my $results = trap("$abs_runprove " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"));
        
        # TEST
        like ($results, qr/DIED. FAILED test 1/,
            "File fails if it doesn't have --blib where there is a required module");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $results = trap("$abs_runprove --lib " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"));
        
        # TEST
        like ($results, qr/All tests successful\./,
            "Good results for the presence of the --lib flag");
        chdir($cwd);
    }
    {
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $results = trap("$abs_runprove " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"));
        
        # TEST
        like ($results, qr/DIED. FAILED test 1/,
            "File fails if it doesn't have --lib where there is a required module");
        chdir($cwd);
    }
    {
        my $results = qx{$runprove --dry $test_file $with_myhello_file};
        
        # TEST
        is ($results, "$test_file\n$with_myhello_file\n",
            "Testing dry run");
    }
    {
        my ($results, $err) = trap("$runprove $simple_fail_file");

        # TEST
        ok (($err !~ m/\n\n$/s),
            "Testing that the output does not end with two ". 
            "newlines on failure."
        );
    }
    {
        local $ENV{'PROVE_SWITCHES'} = "--lib";
        my $cwd = Cwd::getcwd();
        chdir(File::Spec->catdir(File::Spec->curdir(), "t", "sample-tests", "with-lib"));

        my $results = trap("$abs_runprove " . File::Spec->catfile(File::Spec->curdir(), "t", "mytest.t"));
        
        # TEST
        like ($results, qr/All tests successful\./,
            "Good results for the presence of the --lib flag in ENV{PROVE_SWITCHES}");
        chdir($cwd);
    }
    {
        my ($out, $err) = trap($abs_runprove);
        
        # TEST
        is ($out, "",
            "Empty file list does not croak with weird errors (STDOUT)"
        );
        # TEST
        is ($err, "",
            "Empty file list does not croak with weird errors (STDERR)"
        );
    }
}
1;

