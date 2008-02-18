package Test::Run::Straps::EventWrapper;

use strict;
use warnings;

use base 'Test::Run::Base';

__PACKAGE__->mk_accessors(qw(
    _tp_result
));

=head1 NAME

Test::Run::Straps::EventWrapper - a wrapper for a TAP::Parser::Result subclass
which delegates to its methods and has its own methods.

=head1 DESCRIPTION

L<TAP::Parser>'s C<next()> method returns a sub-class of 
L<TAP::Parser::Result>. However, we need to define our own methods
on such objects. Since we cannot inherit from all the sub-classes, we
have created this class which holds an instance of the actual events,
delegates some methods to it, and defines some of its own methods.

=cut

__PACKAGE__->delegate_methods("_tp_result",
    [qw(
        comment
        description
        directive
        explanation
        has_skip
        has_todo
        is_actual_ok
        is_bailout
        is_comment
        is_ok
        is_plan
        is_test
        number
        raw
        tests_planned
    )]
);

sub _initialize
{
    my $self = shift;
    my $args = shift;

    $self->_tp_result($args->{event});

    return 0;
}

=head1 $event->is_pass()

Returns whether the event can be considered a passed event. Always returns a
scalar boolean.

=cut

# TODO:
# Unit test this function to make sure it returns a scalar even in
# list context, in a similar fashion to the || thing.

sub is_pass
{
    my $self = shift;

    foreach my $predicate (qw(is_ok has_todo has_skip))
    {
        if ($self->$predicate())
        {
            return 1;
        }
    }

    return 0;
}

1;
