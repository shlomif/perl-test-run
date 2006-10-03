#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use File::Spec;

sub trap
{
    my $cmd = shift;

    local (*SAVEERR, *ALTERR);
    open ALTERR, ">", "alterr.txt";
    open ALTOUT, ">", "altout.txt";
    open SAVEERR, ">&STDERR";
    open SAVEOUT, ">&STDOUT";
    open STDERR, ">&ALTERR";
    open STDOUT, ">&ALTOUT";
    $cmd->();
    open STDERR, ">&SAVEERR";
    open STDOUT, ">&SAVEOUT";
    close(SAVEERR);
    close(ALTERR);
    close(SAVEOUT);
    close(ALTOUT);

    my $error = do { local $/; local *I; open I, "<", "alterr.txt"; <I>};
    my $output = do { local $/; local *I; open I, "<", "altout.txt"; <I>};
    return ($output, $error);
}


# TEST
require_ok('Test::Run::CmdLine::Iface');

my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");

{
    my $obj =
        Test::Run::CmdLine::Iface->new(
            {
                'test_files' => [ $test_file ],
            }
        );
    # TEST
    ok ($obj, "Construction");
}
# Default behaviour
{
    local %ENV = %ENV;
    
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
    
    my $obj = Test::Run::CmdLine::Iface->new(
        {
            'test_files' => [ $test_file ],
        }
    );

    my ($output, $error) = trap(sub { $obj->run() });
    # TEST
    like ($output, qr/All tests success/,
        "Good output by default");
}

1;

