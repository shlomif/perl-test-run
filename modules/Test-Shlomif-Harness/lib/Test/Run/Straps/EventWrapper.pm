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

=head2 $event->is_pass()

Returns whether the event can be considered a passed event. Always returns a
scalar boolean.

=cut

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

=head2 $self->get_next_test_number()

If this event is a test, then return the next expected test number. Else
return undef.

=cut

sub get_next_test_number
{
    my $self = shift;

    return ($self->is_test() ? ($self->number() +1 ) : undef);
}

=head1 SEE ALSO

L<Test::Run::Straps>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

1;
