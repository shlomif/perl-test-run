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

package Test::Shlomif::Harness::Base::Struct;

use vars (qw(@ISA));

@ISA = (qw(Test::Shlomif::Harness::Base));

sub _pre_init
{
}

sub _get_fields
{
    return [];
}

sub _get_fields_map
{
    my $self = shift;
    return +{ map { $_ => 1 } @{$self->_get_fields()} };
}

sub _initialize
{
    my $self = shift;
    my (%args) = @_;

    $self->_pre_init();

    my $fields_map = $self->_get_fields_map();

    while (my ($k, $v) = each(%args))
    {
        if (exists($fields_map->{$k}))
        {
            $self->set($k, $v);
        }
        else
        {
            die "Called with undefined field \"$k\"";
        }
    }
}


1;

