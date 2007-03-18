#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use File::Spec;

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

    trap{ $obj->run() };
    # TEST
    like ($trap->stdout(), qr/All tests success/,
        "Good output by default");
}

1;

