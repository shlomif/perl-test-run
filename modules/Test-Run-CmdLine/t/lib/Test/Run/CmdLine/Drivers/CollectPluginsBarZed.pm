package Test::Run::CmdLine::Drivers::CollectPluginsBarZed;

use strict;
use warnings;

use MooX qw( late );

extends("Test::Run::CmdLine");

has '+backend_class' => (default => "Test::Run::Drivers::CmdLineTest");

1;

