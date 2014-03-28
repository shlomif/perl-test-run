package Test::Run::Drivers::CmdLineTest;

use strict;
use warnings;

use MooX qw( late );

sub runtests
{
    my $self = shift;
    return +{ 'tested' => [ @{$self->test_files()} ] };
}

1;

