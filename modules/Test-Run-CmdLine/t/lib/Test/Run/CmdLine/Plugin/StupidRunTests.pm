package Test::Run::CmdLine::Plugin::StupidRunTests;

use strict;
use warnings;

use MooX qw( late );

sub BUILD
{
    my $self = shift;

    $self->add_to_backend_plugins("StupidRunTests");
}

1;

