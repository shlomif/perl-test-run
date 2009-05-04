package Test::Run::Drivers::CmdLineTest;

use strict;
use warnings;

use MRO::Compat;

use mro "dfs";

sub _init
{
    my $self = shift;
    $self->next::method(@_);
}

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

