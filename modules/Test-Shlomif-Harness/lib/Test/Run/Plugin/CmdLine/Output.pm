package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use NEXT;

use Text::Sprintf::Named;
use Test::Run::Core;
use Test::Run::Sprintf::Named::FromAccessors;

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

sub _register_obj_formatter
{
    my ($self, $name, $fmt) = @_;

    $self->_formatters->{$name} =
        Test::Run::Sprintf::Named::FromAccessors->new(
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
    {
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
            "premature_test_dubious_summary" =>
                "DIED. %(canonfailed)s",
            "report_skipped_test" =>
                "%(ml)sok%(elapsed)s\n        %(all_skipped_test_msgs)s",
            "report_all_ok_test" =>
                "%(ml)sok%(elapsed)s",
        );

        while (my ($id, $format) = each(%formatters))
        {
            $self->_register_formatter($id, $format);
        }
    }

    {
        my %obj_formatters =
        (
            "skipped_msg" =>
                "%(skipped)s/%(max)s skipped: %(skip_reason)s",
            "bonus_msg" =>
                "%(bonus)s/%(max)s unexpectedly succeeded",
        );

        while (my ($id, $format) = each(%obj_formatters))
        {
            $self->_register_obj_formatter($id, $format);
        }
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

sub _get_defined_skipped_msgs
{
    my ($self, $args) = @_;

    return $self->_format("skipped_msg", { obj => $self->last_test_obj});
}

sub _get_skipped_msgs
{
    my ($self, $args) = @_;

    if ($self->last_test_obj->skipped())
    {
        return [ $self->_get_defined_skipped_msgs() ];
    }
    else
    {
        return [];
    }
}

sub _get_defined_bonus_msg
{
    my ($self, $args) = @_;

    return $self->_format("bonus_msg", { obj => $self->last_test_obj() });
}

sub _get_bonus_msgs
{
    my ($self, $args) = @_;

    return
    [
        ($self->last_test_obj->bonus()) ?
            $self->_get_defined_bonus_msg() :
            ()
    ];
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

sub _first_canonfailed
{
    my $self = shift;

    my ($first) = $self->_canonfailed();

    return $first;
}

sub _report_premature_test_dubious_summary
{
    my $self = shift;

    $self->_named_printf(
        "premature_test_dubious_summary",
        {
            canonfailed => $self->_first_canonfailed(),
        }
    );

    return;
}

sub _report_skipped_test
{
    my $self = shift;

    $self->_named_printf(
        "report_skipped_test",
        {
            ml => $self->last_test_obj->ml(),
            elapsed => $self->last_test_elapsed,
            all_skipped_test_msgs =>
                join(', ', @{$self->_get_all_skipped_test_msgs()}),
        }
    );
}

sub _report_all_ok_test
{
    my ($self, $args) = @_;

    $self->_named_printf(
        "report_all_ok_test",
        {
            ml => $self->last_test_obj->ml(),
            elapsed => $self->last_test_elapsed,
        }
    );
}
sub _report_failed_before_any_test_output
{
    my $self = shift;

    $self->_print("FAILED before any test output arrived");
}

=head1 LICENSE

This code is licensed under the MIT X11 License.

=cut

1;

