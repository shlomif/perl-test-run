package Test::Run::CmdLine::Plugin::FooField;

use strict;
use warnings;

use MooX qw( late );

sub BUILD
{
    my $self = shift;

    $self->add_to_backend_plugins("FooField");
}

1;

