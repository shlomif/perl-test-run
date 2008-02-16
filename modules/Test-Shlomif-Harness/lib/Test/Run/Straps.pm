package Test::Run::Straps;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.26';

use base 'Test::Run::Straps_GplArt';

my @fields= (qw(
    bailout_reason
    callback
    Debug
    error
    _event
    exception
    file
    _file_handle
    _file_totals
    _is_macos
    _is_vms
    _is_win32
    last_test_print
    lone_not_line
    max
    next
    _old5lib
    _parser
    results
    saw_bailout
    saw_header
    _seen_header
    Switches
    Switches_Env
    Test_Interpreter
    todo
    too_many_tests
    totals
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub _invoke_cb
{
    my $self = shift;
    my $args = shift;

    if ($self->callback())
    {
        $self->callback()->(
            $args
        );
    }
}

sub _calc__analyze_event__callbacks
{
    my $self = shift;

    return [qw(
        _handle_event
        _call_callback
        _bump_next
    )];
}

sub _analyze_event
{
    my $self = shift;

    foreach my $cb (@{$self->_calc__analyze_event__callbacks()})
    {
        $self->$cb();
    }

    return;
}

1;

=head1 NAME

Test::Run::Straps - analyse the test results by using TAP::Parser.

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish <shlomif@iglu.org.il>
