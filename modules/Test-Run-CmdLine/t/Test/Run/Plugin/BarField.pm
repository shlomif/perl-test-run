package Test::Run::Plugin::BarField;

use strict;
use warnings;

use NEXT;

sub runtests
{
    my $self = shift;
    my $ret = $self->NEXT::runtests(@_);
    $ret->{'bar'} = "habar sheli";
    return $ret;
}

1;
