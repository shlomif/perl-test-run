package Test::Run::Sprintf::Named::FromAccessors;

use strict;
use warnings;

use base 'Text::Sprintf::Named';

sub calc_param
{
    my ($self, $args) = @_;

    my $method = $args->{name};

    return $args->{named_params}->{obj}->$method();
}

1;

