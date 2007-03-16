#!/usr/bin/perl

use strict;
use warnings;

package main;

use Test::More tests => 1;

use Config;
use File::Spec;
use Cwd;

use YAML ();

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
my $suc2_mok_file = File::Spec->catfile($sample_tests_dir, "success2.mok.cat");
my $suc1_cat_file = File::Spec->catfile($sample_tests_dir, "success1.cat");
my $one_ok_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $suc1_mok_file = File::Spec->catfile($sample_tests_dir, "success1.mok");

my $config_file = Cwd::abs_path(
    File::Spec->catfile(
        File::Spec->curdir(), "t", "data", "config-files", "mokcat1.yml",
    )
);

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
    delete($ENV{'HARNESS_ALT_INTRP_FILE'});

    $ENV{'HARNESS_PLUGINS'} = "AlternateInterpreters";
    
    {
        local $ENV{'HARNESS_ALT_INTRP_FILE'} = $config_file;

        my $yaml_data =
        [
            {
                cmd => 
                ("$^X " . File::Spec->catfile(
                    File::Spec->curdir(), "t", "data", 
                    "interpreters", "mini-ok.pl"
                    ) . " "
                ),
                type => "regex",
                pattern => '\.mok(?:\.cat)?\z',
            },
            {
                cmd => 
                ("$^X " . File::Spec->catfile(
                    File::Spec->curdir(), "t", "data", 
                    "interpreters", "cat.pl"
                    ) . " "
                ),
                type => "regex",
                pattern => '\.cat\z',
            },
        ];

        YAML::DumpFile($config_file, $yaml_data);

        my $results = trap("runprove $suc2_mok_file $suc1_cat_file" . 
            " $one_ok_file $suc1_mok_file");

        # TEST
        ok (($results =~ m/All tests successful\./), "All tests were successful with the new interpreters");
    }
}

END:

