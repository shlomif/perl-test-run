package Test::Run::CmdLine::Plugin::FooField;

use strict;
use warnings;

use NEXT;

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("FooField");
}

1;

