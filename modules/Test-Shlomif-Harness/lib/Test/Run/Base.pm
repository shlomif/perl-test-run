package Test::Run::Base;

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

package Test::Run::Base::Struct;

use vars (qw(@ISA));

@ISA = (qw(Test::Run::Base));

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

sub inc_field
{
    my ($self, $field) = @_;
    return $self->add_to_field($field, 1);
}

sub add_to_field
{
    my ($self, $field, $diff) = @_;
    if (exists($self->_get_fields_map()->{$field}))
    {
        $self->set($field, $self->get($field)+$diff);
    }
    else
    {
        die "Trying to increment non-existent field \"$field\"";
    }
}

1;

