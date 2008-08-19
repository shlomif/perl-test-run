#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/";

use Test::More tests => 1;

use Test::Run::CmdLine::Iface;
use Test::Run::CmdLine::Drivers::CmdLineTest;
use Test::Run::Drivers::CmdLineTest;

{
    local %ENV=%ENV;
    delete $ENV{HARNESS_DRIVER};

    {
        local @Test::Run::CmdLine::Drivers::CmdLineTest::ISA;
        local @Test::Run::Drivers::CmdLineTest::ISA;
        my $iface = Test::Run::CmdLine::Iface->new(
            {
                'driver_plugins' => [qw(ZedField BarFieldWithAccum)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $driver = $iface->_calc_driver();

        # TEST
        is_deeply(
            $driver->backend_plugins(),
            [qw(ZedField BarField)],
        );
    }
}

1;

