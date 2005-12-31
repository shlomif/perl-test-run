package Test::Run::Drivers::CmdLineTest;

use strict;
use warnings;

sub _initialize
{
    my $self = shift;
    $self->SUPER::_initialize(@_);
}

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

