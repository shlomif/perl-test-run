package Test::Run::Output;

use strict;
use warnings;

use base 'Test::Run::Output_GplArt';

__PACKAGE__->mk_accessors(qw(NoTty Verbose last_test_print ml));

=head1 NAME

Test::Run::Output - Base class for outputting messages to the user in a test
harmess.

=cut

sub _initialize
{
    my ($self, $args) = @_;

    $self->Verbose($args->{Verbose});
    $self->NoTty($args->{NoTty});

    return 0;
}

sub _print_message_raw
{
    my ($self, $msg) = @_;
    print $msg;
}

sub print_message
{
    my ($self, $msg) = @_;

    $self->_print_message_raw($msg);
    $self->_newline();

    return;
}

sub _newline
{
    my $self = shift;
    $self->_print_message_raw("\n");
}

sub print_leader
{
    my ($self, $args) = @_;

    $self->_print_message_raw(
        $self->_mk_leader(
            $args->{filename},
            $args->{width}
        )
    );
}
1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
