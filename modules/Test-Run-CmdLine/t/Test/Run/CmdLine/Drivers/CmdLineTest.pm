package Test::Run::CmdLine::Drivers::CmdLineTest;

use strict;
use warnings;

use vars qw(@ISA);

use Test::Run::Obj;

@ISA=(qw(Test::Run::Obj));

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

