#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/";

use Test::More tests => 4;

use Test::Run::CmdLine::Iface;

{
    local %ENV=%ENV;
    delete $ENV{HARNESS_DRIVER};

    {
        my $iface = Test::Run::CmdLine::Iface->new();

        # TEST
        is ($iface->driver_class(), "Test::Run::CmdLine::Drivers::Default", 
            "Right default driver_class");
            
    }
 
    {
        local $ENV{HARNESS_DRIVER} = "Foo::Bar";
        my $iface = Test::Run::CmdLine::Iface->new();

        # TEST
        is ($iface->driver_class(), "Foo::Bar", 
            "Right driver_class set from ENV");
    }
    
    {
        my $iface = Test::Run::CmdLine::Iface->new(
            'driver_class' => "Test::Run::CmdLine::Drivers::CmdLineTest",
            'test_files' => [qw(one.t TWO tHREE)],
        );
        # TEST
        is ($iface->driver_class(), "Test::Run::CmdLine::Drivers::CmdLineTest", 
            "Right driver_class set from ENV");

        my $got = $iface->run();
        # TEST
        is_deeply($got, +{'tested' => [qw(one.t TWO tHREE)] },
            "Returns what you want.");
    }
}

1;

