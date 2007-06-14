package MyTestRun::Plug::P::Two;

use strict;
use warnings;

use NEXT;

sub my_calc_last
{
    my $self = shift;

    return "If you want the last name, it is: " . $self->NEXT::my_calc_last();
}

1;

