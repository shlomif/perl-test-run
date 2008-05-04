package Test::Run::Base::Struct;

use strict;
use warnings;

=head1 NAME

Test::Run::Base::Struct - base class for Test::Run's "structs", that are
simple classes that hold several values.

=head1 DESCRIPTION

Inherits from L<Test::Run::Base>.

=cut

use NEXT;

use base 'Test::Run::Base';

sub _pre_init
{
}

sub _get_fields
{
    my $self = shift;

    return $self->accum_array(
        {
            method => "_get_private_fields",
        }
    );
}

sub _get_fields_map
{
    my $self = shift;
    return +{ map { $_ => 1 } @{$self->_get_fields()} };
}

use Carp;

sub _init
{
    my $self = shift;

    $self->NEXT::_init(@_);

    my ($args) = @_;
    
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

=head1 METHODS

=head2 $struct->inc_field($field_name)

Increment the slot $field_name by 1.

=cut

sub inc_field
{
    my ($self, $field) = @_;
    return $self->add_to_field($field, 1);
}

=head2 $struct->add_to_field($field_name, $difference)

Add $difference to the slot $field_name.

=cut

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

__END__

=head1 SEE ALSO

L<Test::Run::Base>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

