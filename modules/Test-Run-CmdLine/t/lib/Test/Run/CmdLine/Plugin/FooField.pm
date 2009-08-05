package Test::Run::CmdLine::Plugin::FooField;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub _init
{
    my $self = shift;
    $self->next::method(@_);
    $self->add_to_backend_plugins("FooField");
}

1;

