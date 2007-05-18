package Test::Run::CmdLine::Drivers::CmdLineTest;

use strict;
use warnings;

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->backend_class("Test::Run::Drivers::CmdLineTest");
}

1;

