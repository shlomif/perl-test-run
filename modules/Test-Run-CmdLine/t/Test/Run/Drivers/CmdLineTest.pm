package Test::Run::Drivers::CmdLineTest;

use strict;
use warnings;

use NEXT;

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
}

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

