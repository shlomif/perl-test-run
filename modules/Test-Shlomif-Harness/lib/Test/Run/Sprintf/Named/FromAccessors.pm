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

sub obj_format
{
    my ($self, $obj, $other_args) = @_;

    $other_args ||= {};

    return $self->format({args => {obj => $obj, %$other_args}});
}

1;

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php
