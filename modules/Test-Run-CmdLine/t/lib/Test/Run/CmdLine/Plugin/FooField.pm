package Test::Run::CmdLine::Plugin::FooField;

use strict;
use warnings;

use NEXT;

sub _init
{
    my $self = shift;
    $self->NEXT::_init(@_);
    $self->add_to_backend_plugins("FooField");
}

1;

