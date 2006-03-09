#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use Test::Run::CmdLine::Prove;

sub mytest
{
    my $args = shift;
    local @ARGV = @$args;
    my $prove = Test::Run::CmdLine::Prove->new();
    return $prove->ext_regex_string();
}

# TEST
is (mytest ([qw{t/hello.t}]), '\.(?:t)$', "Testing for default extension");
# TEST
is (mytest ([qw{--ext=cgi t}]), '\.(?:cgi)$', "Testing for single extension");
# TEST
is (mytest (['--ext=cgi,pl', 't']), '\.(?:cgi|pl)$', 
    "Testing for extensions separated with commas");
# TEST
is (mytest (['--ext=cgi,.pl', '--ext=.hello,perl', 't']), 
    '\.(?:cgi|pl|hello|perl)$',
    "Testing for several extension args along with periods"
);


