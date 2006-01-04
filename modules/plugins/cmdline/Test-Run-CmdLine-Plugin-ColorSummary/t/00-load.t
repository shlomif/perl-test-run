#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::CmdLine::Plugin::ColorSummary' );
}

diag( "Testing Test::Run::CmdLine::Plugin::ColorSummary $Test::Run::CmdLine::Plugin::ColorSummary::VERSION, Perl $], $^X" );
