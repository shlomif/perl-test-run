#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Run::CmdLine;

{
    my $obj = Test::Run::CmdLine->new();
    # TEST
    ok($obj->_is_class_name("Test::Run::CmdLine::Driver::MyTest"), "Class name ok");
    # TEST
    ok($obj->_is_class_name("hello::world"), "Class name ok");
    # TEST
    ok((! $obj->_is_class_name(qq(Test::Run::Hello"; print "Hello\n";))), 
        "Prevent injected code");
    # TEST
    ok($obj->_is_class_name("_Hello_Test_::Run_tests"), 
        "Underscores");
}
1;

