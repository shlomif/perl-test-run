package MyTestRun::Plug::P::One;

use strict;
use warnings;

use NEXT;

sub my_calc_first
{
    my $self = shift;

    return "First is {{{" . $self->NEXT::my_calc_first() . "}}}";
}

1;
