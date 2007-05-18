package Test::Run::Base;

use strict;
use warnings;

use base 'Class::Accessor';

use Text::Sprintf::Named;
use Test::Run::Sprintf::Named::FromAccessors;

use Test::Run::Class::Hierarchy (qw(hierarchy_of rev_hierarchy_of));

__PACKAGE__->mk_accessors(qw(
    _formatters
));

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

sub _get_formatter
{
    my ($self, $fmt) = @_;

    return
        Text::Sprintf::Named->new(
            { fmt => $fmt, },
        );
}

sub _register_formatter
{
    my ($self, $name, $fmt) = @_;

    $self->_formatters->{$name} = $self->_get_formatter($fmt);

    return;
}

sub _get_obj_formatter
{
    my ($self, $fmt) = @_;

    return
        Test::Run::Sprintf::Named::FromAccessors->new(
            { fmt => $fmt, },
        );    
}

sub _register_obj_formatter
{
    my ($self, $name, $fmt) = @_;

    $self->_formatters->{$name} = $self->_get_obj_formatter($fmt);

    return;
}

sub _format
{
    my ($self, $format, $args) = @_;

    if (ref($format) eq "")
    {
        return $self->_formatters->{$format}->format({ args => $args});
    }
    else
    {
        return $self->_get_formatter(${$format})->format({ args => $args});
    }
}

sub accum_array
{
    my ($self, $args) = @_;

    my $method_name = $args->{method};

    my $class = ref($self);

    my $hierarchy = hierarchy_of($class);

    my @results;
    foreach my $isa_class (@$hierarchy)
    {
        no strict 'refs';
        my $method = ${$isa_class . "::"}{$method_name};
        if (defined($method))
        {
            push @results, @{$method->($self)};
        }
    }
    return \@results;
}
1;

__END__

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

