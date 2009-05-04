package Test::Run::CmdLine::Plugin::Super;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub _init
{
    my $self = shift;
    $self->next::method(@_);
    $self->add_to_backend_plugins("Super");
}

1;

