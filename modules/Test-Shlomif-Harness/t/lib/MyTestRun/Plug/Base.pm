package MyTestRun::Plug::Base;

use strict;
use warnings;

use base 'Test::Run::Base::Struct';

my @fields = (qw(first last));
__PACKAGE__->mk_accessors(@fields);

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

