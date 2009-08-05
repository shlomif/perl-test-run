package Test::Run::CmdLine::Plugin::StupidRunTests;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub _init
{
    my $self = shift;
    $self->next::method(@_);
    $self->add_to_backend_plugins("StupidRunTests");
}

1;

