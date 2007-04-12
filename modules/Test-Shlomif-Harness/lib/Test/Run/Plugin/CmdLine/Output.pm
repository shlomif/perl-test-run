package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use NEXT;

use Test::Run::Core;

=head1 NAME

Test::Run::Plugin::CmdLine::Output - the default output plugin for
Test::Run::CmdLine.

=head1 MOTIVATION

This class will gradually re-implement all of the 
L<Test::Run::Plugin::CmdLine::Output::GplArt> functionality to 
avoid license complications. At the moment it inherits from it.

=cut


use base 'Test::Run::Plugin::CmdLine::Output::GplArt';

__PACKAGE__->mk_accessors(qw(
    output
));

sub _get_new_output
{
    my ($self, $args) = @_;

    return Test::Run::Output->new($args);
}


sub _initialize
{
    my $self = shift;

    my ($args) = @_;

    $self->output($self->_get_new_output($args));

    return $self->NEXT::_initialize(@_);
}

sub _get_dubious_message_ml
{
    my $self = shift;
    return $self->last_test_obj->ml();
}

sub _get_dubious_verdict_message
{
    return "dubious";
}

sub _get_callbacks_list_for_dubious_message
{
    my $self = shift;

    return [qw(
        _get_dubious_message_ml
        _get_dubious_verdict_message
        _get_dubious_message_line_end
        _get_dubious_status_message_indent_prefix
        _get_dubious_status_message
    )];
}

sub _get_dubious_message_components
{
    my $self = shift;

    return 
    [ 
        map { my $cb = $_; $self->$cb() } 
        @{$self->_get_callbacks_list_for_dubious_message()}
    ];
}

sub _get_dubious_message_line_end
{
    return "\n";
}

=head1 LICENSE

This code is licensed under the MIT X11 License.

=cut

1;

