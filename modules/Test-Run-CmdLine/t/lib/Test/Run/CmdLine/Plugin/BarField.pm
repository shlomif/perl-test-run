package Test::Run::CmdLine::Plugin::BarField;

use strict;
use warnings;

sub _init
{
    my $self = shift;
    $self->next::method(@_);
    $self->add_to_backend_plugins("BarField");
}

1;

