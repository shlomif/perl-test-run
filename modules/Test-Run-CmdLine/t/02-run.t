#!/usr/bin/perl

use strict;
use warnings;

use lib "./t/";

use Test::More tests => 3;

use Test::Run::CmdLine;

{
    local %ENV;
    delete $ENV{TEST_HARNESS_DRIVER};

    {
        my $iface = Test::Run::CmdLine->new();

        # TEST
        is ($iface->driver_class(), "Test::Run::Obj", 
            "Right default driver_class");
            
    }
 
    {
        local $ENV{TEST_HARNESS_DRIVER} = "Foo::Bar";
        my $iface = Test::Run::CmdLine->new();

        # TEST
        is ($iface->driver_class(), "Foo::Bar", 
            "Right driver_class set from ENV");
            
    }
    
    {
        my $iface = Test::Run::CmdLine->new(
            'driver_class' => "Test::Run::CmdLine::Drivers::CmdLineTest",
            'test_files' => [qw(one.t TWO tHREE)],
        );

        my $got = $iface->run();
        # TEST
        is_deeply($got, +{'tested' => [qw(one.t TWO tHREE)] },
            "Returns what you want.");
    }
}

1;

