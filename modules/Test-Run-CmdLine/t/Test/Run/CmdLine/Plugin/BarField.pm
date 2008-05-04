package Test::Run::CmdLine::Plugin::BarField;

use strict;
use warnings;

sub _init
{
    my $self = shift;
    $self->NEXT::_init(@_);
    $self->add_to_backend_plugins("BarField");
}

1;

