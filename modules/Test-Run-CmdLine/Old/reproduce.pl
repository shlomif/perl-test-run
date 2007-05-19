#!/usr/bin/perl

use lib "./t";
use strict;
use warnings;

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
                'driver_plugins' => [qw(FooField BarField StupidRunTests)],
                'test_files' => [qw(one.t TWO tHREE)],
            }
        );

        my $got = $iface->run();

    }
}

1;

