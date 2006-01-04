package Test::Run::CmdLine::Plugin::Super;

use strict;
use warnings;

use NEXT;

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("Super");
}

1;

