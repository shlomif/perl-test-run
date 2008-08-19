package Test::Run::CmdLine::Plugin::Super;

use strict;
use warnings;

use NEXT;

sub _init
{
    my $self = shift;
    $self->NEXT::_init(@_);
    $self->add_to_backend_plugins("Super");
}

1;

