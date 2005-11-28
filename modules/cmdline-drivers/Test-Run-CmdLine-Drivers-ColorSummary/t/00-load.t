#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::CmdLine::Drivers::ColorSummary' );
}

diag( "Testing Test::Run::CmdLine::Drivers::ColorSummary $Test::Run::CmdLine::Drivers::ColorSummary::VERSION, Perl $], $^X" );
