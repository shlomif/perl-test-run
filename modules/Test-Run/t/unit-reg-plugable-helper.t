#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 1;

package MyClass;

use Moose;

extends ('Test::Run::Base::PlugHelpers');

sub _init
{
    return;
}

package main;

{
    my $obj = MyClass->new();
    eval
    {
        $obj->register_pluggable_helper(
            {
                id => "foo",
                base => "MyClass::Foo",
            },
        );
    };

    my $Err = $@;

    # TEST
    like ($Err, qr{\A\s*'?"collect_plugins_method" not specified},
        "Missing collect_plugins_method",
    );
}

