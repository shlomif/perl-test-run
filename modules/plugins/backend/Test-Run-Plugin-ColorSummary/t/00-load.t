#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Test::Run::Plugin::ColorSummary' );
}

diag( "Testing Test::Run::Plugin::ColorSummary $Test::Run::Plugin::ColorSummary::VERSION, Perl $], $^X" );
