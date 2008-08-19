package Test::Run::CmdLine::Plugin::StupidRunTests;

use strict;
use warnings;

use NEXT;

sub _init
{
    my $self = shift;
    $self->NEXT::_init(@_);
    $self->add_to_backend_plugins("StupidRunTests");
}

1;

