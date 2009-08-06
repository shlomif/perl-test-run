package MyTestRun::Plug::Base;

use strict;
use warnings;

use Moose;

extends(qw(
    Test::Run::Base::Struct
    ));

my @fields = (qw(first last));

has 'first' => (is => "rw");
has 'last' => (is => "rw");

sub _get_private_fields
{
    my $self = shift;

    return [@fields];
}

sub my_calc_first
{
    my $self = shift;

    return $self->first();
}

sub my_calc_last
{
    my $self = shift;

    return $self->last();
}

1;

