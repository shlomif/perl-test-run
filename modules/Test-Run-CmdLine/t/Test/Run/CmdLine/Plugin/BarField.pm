package Test::Run::CmdLine::Plugin::BarField;

use strict;
use warnings;

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("BarField");
}

1;

