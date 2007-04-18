package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use NEXT;

use Text::Sprintf::Named;
use Test::Run::Core;

use base 'Test::Run::Plugin::CmdLine::Output::GplArt';

=head1 NAME

Test::Run::Plugin::CmdLine::Output - the default output plugin for
Test::Run::CmdLine.

=head1 MOTIVATION

This class will gradually re-implement all of the 
L<Test::Run::Plugin::CmdLine::Output::GplArt> functionality to 
avoid license complications. At the moment it inherits from it.

=cut


__PACKAGE__->mk_accessors(qw(
    _formatters
    output
));

sub _get_new_output
{
    my ($self, $args) = @_;

    return Test::Run::Output->new($args);
}

sub _register_formatter
{
    my ($self, $name, $fmt) = @_;

    $self->_formatters->{$name} =
        Text::Sprintf::Named->new(
            { fmt => $fmt, },
        );

    return;
}

sub _format
{
    my ($self, $name, $args) = @_;

    return $self->_formatters->{$name}->format({ args => $args});
}

sub _print
{
    my ($self, $string) = @_;

    return $self->output()->print_message($string);
}

sub _named_printf
{
    my ($self, $format, $args) = @_;

    return
        $self->_print(
            $self->_format($format, $args),
        );
}

sub _initialize
{
    my $self = shift;

    my ($args) = @_;

    $self->output($self->_get_new_output($args));
    $self->_formatters({});

    my %formatters =
    (
        "dubious_status" =>
            "Test returned status %(estatus)s (wstat %(wstatus)d, 0x%(wstatus)x)",
        "vms_status" =>
            "\t\t(VMS status is %(estatus)s)",
        "test_file_closing_error" =>
            "can't close %(file)s. %(error)s",
        "could_not_run_script" =>
            "can't run %(file)s. %(error)s",
        "test_file_opening_error" =>
            "can't open %(file)s. %(error)s",
    );

    while (my ($id, $format) = each(%formatters))
    {
        $self->_register_formatter($id, $format);
    }

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

sub _get_dubious_status_message_indent_prefix
{
    return "\t";
}

sub _get_dubious_status_message
{
    my $self = shift;

    return $self->_format("dubious_status",
        {
            estatus => $self->_get_estatus(),
            wstatus => $self->_get_wstatus(),
        }
    );
}

sub _get_dubious_message
{
    my $self = shift;

    return join("",
        @{$self->_get_dubious_message_components()}
    );
}

sub _report_dubious_summary_all_subtests_successful
{
    my $self = shift;

    $self->_print("\tafter all the subtests complete successfully");
}

sub _vms_specific_report_dubious
{
    my ($self) = @_;

    if ($^O eq "VMS")
    {
        $self->_named_printf(
            "vms_status",
            { estatus => $self->_get_estatus() },
        );
    }
}

sub _report_dubious
{
    my ($self) = @_;

    $self->_print($self->_get_dubious_message());
    $self->_vms_specific_report_dubious();
}

sub _get_leaked_files_string
{
    my ($self, $args) = @_;

    return join(" ", sort @{$args->{leaked_files}});
}

sub _report_leaked_files
{
    my ($self, $args) = @_;
    
    $self->_print("LEAKED FILES: " . $self->_get_leaked_files_string($args));
}

sub _handle_test_file_closing_error
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "test_file_closing_error",
        $args,
    );
}

sub _report_could_not_run_script
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "could_not_run_script",
        $args,
    );
}

sub _handle_test_file_opening_error
{
    my ($self, $args) = @_;

    return $self->_named_printf(
        "test_file_opening_error",
        $args,
    );
}

sub _get_skipped_msgs
{
    my ($self) = @_;

    my $test = $self->last_test_obj();

    if ($test->skipped())
    {
        return
        [
            sprintf(
                "%s/%s skipped: %s",
                $test->skipped, $test->max, $test->skip_reason
            )
        ];
    }
    else
    {
        return [];
    }
}

sub _get_all_skipped_test_msgs
{
    my ($self) = @_;
    return
    [
        @{$self->_get_skipped_msgs()}, 
        @{$self->_get_bonus_msgs()}
    ];
}

sub _report_single_test_file_start_leader
{
    my ($self, $args) = @_;

    $self->output()->last_test_print(0);
    $self->output()->print_leader(
        {
            filename => $args->{test_file},
            width => $self->width(),
        }
    );
}

sub _report_single_test_file_start_debug
{
    my ($self, $args) = @_;

    if ($self->Debug())
    {
        $self->_print(
            "# Running: " . $self->Strap()->_command_line($args->{test_file})
        );
    }
}

sub _report_single_test_file_start
{
    my ($self, $args) = @_;

    $self->_report_single_test_file_start_leader($args);

    $self->_report_single_test_file_start_debug($args);

    return;
}

sub _calc_test_struct_ml
{
    my $self = shift;

    return $self->output->ml;
}

=head1 LICENSE

This code is licensed under the MIT X11 License.

=cut

1;

