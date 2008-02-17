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
        is_ok
        is_test
        number
        tests_planned
    )]
);

1;


