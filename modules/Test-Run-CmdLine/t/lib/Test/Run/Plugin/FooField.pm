package Test::Run::Plugin::FooField;

use strict;
use warnings;

use NEXT;

sub runtests
{
    my $self = shift;
    my $ret = $self->NEXT::runtests(@_);
    $ret->{'foo'} = "myfoo";
    return $ret;
}

1;

