package Test::Run::CmdLine::Drivers::CollectPluginsBarZed;

use strict;
use warnings;

sub _init
{
    my $self = shift;
    $self->next::method(@_);
    $self->backend_class("Test::Run::Drivers::CmdLineTest");
}

1;

