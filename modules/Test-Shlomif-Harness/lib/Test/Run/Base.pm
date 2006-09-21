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

=head2 $dest->copy_from($source, [@fields])

Assigns the fields C<@fields> using their accessors based on their values
in C<$source>.

=cut

sub copy_from
{
    my ($dest, $source, $fields) = @_;

    foreach my $f (@$fields)
    {
        $dest->$f($source->$f());
    }

    return;
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

use Carp;

sub _initialize
{
    my ($self, $args) = @_;
    
    Carp::confess '$args not a hash' if (ref($args) ne "HASH");
    $self->_pre_init();

    my $fields_map = $self->_get_fields_map();

    while (my ($k, $v) = each(%$args))
    {
        if (exists($fields_map->{$k}))
        {
            $self->set($k, $v);
        }
        else
        {
            Carp::confess "Called with undefined field \"$k\"";
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
        Carp::confess "Trying to increment non-existent field \"$field\"";
    }
}

1;

