package Test::Run::Drivers::CmdLineTestBare;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub _init
{
    my $self = shift;
    $self->next::method(@_);
}

1;

