package Test::Shlomif::Harness::Base;

use strict;
use warnings;

use Class::Accessor;

use vars (qw(@ISA));

@ISA = (qw(Class::Accessor));

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

1;

