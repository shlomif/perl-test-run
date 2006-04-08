#!/usr/bin/perl

use strict;
use warnings;

package main;

use Test::More tests => 2;

use Term::ANSIColor;
use Config;
use File::Spec;
use Cwd;

my $alterr_filename = "alterr.txt";
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
my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $several_oks_file = File::Spec->catfile($sample_tests_dir, "several-oks.t");
my $one_fail_file = File::Spec->catfile($sample_tests_dir, "one-fail.t");

{
    local %ENV = %ENV;
    
    $ENV{'PERL5LIB'} = $abs_lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
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
    delete($ENV{'HARNESS_SUMMARY_COL_SUC'});
    delete($ENV{'HARNESS_SUMMARY_COL_FAIL'});

    $ENV{'HARNESS_PLUGINS'} = "ColorSummary";
    
    {
        my $results = trap("runprove $test_file $several_oks_file");
        
        my $color = color("bold blue");

        # TEST
        ok (($results =~ m/\Q${color}\EAll tests successful\./), "'All tests successful.' string as is");
    }

    {
        my ($results, $err_text) = trap("runprove $one_fail_file");
        my $color = color("bold red");

        # TEST
        ok (($err_text =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
            qq{Found colored "Failed 1/1" string});

    }
}

goto END;
{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/several-oks.t"
        ],
        summary_color_success => "green",
        summary_color_failure => "yellow",
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    my $color = color("green");

    # ++TEST
    ok (($text =~ m/\Q${color}\EAll tests successful\./), 
        "Text is colored green on explicity SummaryColor_success");
}

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    open ALTERR, ">", "alterr.txt";
    open SAVEERR, ">&STDERR";
    open STDERR, ">&ALTERR";

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-fail.t",
        ],
        summary_color_success => "green",
        summary_color_failure => "yellow",
        );

    eval {
    $tester->runtests();
    };
    my $err = $@;

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    open STDERR, ">&SAVEERR";
    close(SAVEERR);
    close(ALTERR);

    my $err_text = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};

    my $color = color("yellow");

    # ++TEST
    ok (($err_text =~ m/\Q${color}\EFailed 1\/1 test scripts/), 
        qq{Found colored "Failed 1/1" string with user-specified color});
    # ++TEST
    ok ($err, qq{Exited with an exception});
}

END:

