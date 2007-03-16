package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use NEXT;

use Test::Run::Core;

=head1 Test::Run::Plugin::CmdLine::Output

This a module that implements the command line/STDOUT specific output of 
L<Test::Run::Obj>, which was taken out of L<Test::Run::Core> to increase
modularity.

=cut

use vars qw(@ISA);

@ISA=(qw(Test::Run::Core));

__PACKAGE__->mk_accessors(qw(
    output
));

sub _get_new_output
{
    my $self = shift;
    my $args = shift;

    return Test::Run::Output->new(
        $args,
    );
}

sub _initialize
{
    my $self = shift;

    my ($args) = @_;

    $self->output($self->_get_new_output($args));

    return $self->NEXT::_initialize(@_);
}

sub _report_dubious
{
    my ($self) = @_;
    my $test = $self->last_test_obj;
    my $estatus = $self->_get_estatus();

    $self->output()->print_message(
        sprintf($test->ml()."dubious\n\tTest returned status $estatus ".
            "(wstat %d, 0x%x)",
            (($self->_get_wstatus()) x 2))
        );
    if ($^O eq "VMS")
    {
        $self->output()->print_message("\t\t(VMS status is $estatus)");
    }
}

sub _report_leaked_files
{
    my ($self, $args) = (@_);

    my @f = sort @{$args->{leaked_files}};

    $self->output()->print_message("LEAKED FILES: @f");
}

sub _get_skipped_msgs
{
    my ($self) = @_;

    my $test = $self->last_test_obj();

    if ($test->skipped())
    {
        return 
        [
            ($test->skipped()."/".$test->max()." skipped: ".
            $test->skip_reason())
        ];
    }
    else
    {
        return [];
    }
}

sub _get_bonus_msgs
{
    my ($self, $args) = @_;

    my $test = $self->last_test_obj;

    if ($test->bonus())
    {
        return
        [
            ($test->bonus()."/".$test->max()." unexpectedly succeeded")
        ];
    }
    else
    {
        return [];
    };
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

sub _report_skipped_test
{
    my ($self) = @_;

    my $test = $self->last_test_obj();
    my $elapsed = $self->last_test_elapsed();

    $self->output()->print_message(
        $test->ml()."ok$elapsed\n        ".
        join(', ', @{$self->_get_all_skipped_test_msgs()})
    );
}

sub _report_failed_before_any_test_output
{
    my $self = shift;

    $self->output()->print_message("FAILED before any test output arrived");
}

sub _report_all_ok_test
{
    my ($self, $args) = @_;

    my $test = $self->last_test_obj;
    my $elapsed = $self->last_test_elapsed;

    $self->output()->print_message($test->ml()."ok$elapsed");

    return;
}

sub _report_all_skipped_test
{
    my ($self, $args) = @_;

    my $test = $self->last_test_obj;

    $self->output()->print_message(
        "skipped\n        all skipped: " . $test->get_reason()
        );
}

sub _fail_other_print_bonus_message
{
    my $self = shift;
    
    my $bonusmsg = $self->_bonusmsg() || "";
    $bonusmsg =~ s/^,\s*//;
    if ($bonusmsg)
    {
        $self->output()->print_message("$bonusmsg.");
    }
}

sub _report_failed_with_results_seen
{
    my ($self) = @_;

    $self->output()->print_message(
        $self->_get_failed_with_results_seen_msg(),
    );
}

sub _report_single_test_file_start
{
    my ($self, $args) = @_;

    $self->output()->last_test_print(0); # so each test prints at least once
    $self->output()->print_leader({
        filename => $args->{test_file},
        width => $self->width(),
    });

    if ( $self->Debug() )
    {
        $self->output()->print_message(
            "# Running: " . $self->Strap()->_command_line($args->{test_file})
        );
    }

    return;
}

sub _report
{
    my ($self, $args) = @_;
    my $event = $args->{'event'};
    my $msg;
    if ($event->{type} eq "success")
    {
        $msg = $self->_get_success_msg();
    }
    else
    {
        confess "Unknown \$event->{type} passed to _report!";
    }

    return $self->output()->print_message($msg);
}

sub _fail_other_print_top
{
    my $self = shift;

    my $max_namelen = $self->max_namelen();

    $self->output()->print_message(
        sprintf("%-${max_namelen}s", $self->_get_format_failed_str()) .
        $self->_get_format_middle_str() .
        $self->_get_format_list_str()
    );
    $self->output()->print_message("-" x $self->format_columns());
}

sub _report_final_stats
{
    my ($self) = @_;

    my $tot = $self->tot();

    $self->output()->print_message(
        sprintf("Files=%d, Tests=%d, %s",
           $tot->files(), $tot->max(), timestr($tot->bench(), 'nop'))
       );
}

sub _fail_other_report_test
{
    my $self = shift;
    my $script = shift;

    my $test = $self->failed_tests()->{$script};
    my $max_namelen = $self->max_namelen();
    my $list_len = $self->list_len();

    my @canon = split(/\s+/, $test->canon());

    my $canon_strings = $self->_fail_other_get_canon_strings([@canon]);
    
    $self->output()->print_message(
        sprintf(
            ("%-" . $max_namelen . "s  " . 
                "%3s %5s %5s %4s %6.2f%%  %s"),
            $test->name(), $test->estat(),
            $test->wstat(), $test->max(),
            $test->failed(), $test->_defined_percent(),
            shift(@$canon_strings)
        )
    );
    foreach my $c (@$canon_strings)
    {
        $self->output()->print_message(
            sprintf((" " x ($self->format_columns() - $list_len) . 
                "%s"),
                $c
            ),
        );
    }
}

sub _report_dubious_summary_all_subtests_successful
{
    my ($self) = @_;

    $self->output()->print_message("\tafter all the subtests completed successfully");
}

sub _report_premature_test_dubious_summary
{
    my ($self) = @_;

    my $test = $self->last_test_obj;

    my ($txt) = $self->_canonfailed($test);

    $self->output()->print_message("DIED. " . $txt);
}

sub _calc_test_struct_ml
{
    my $self = shift;

    return $self->output()->ml();
}

sub _report_tap_event
{
    my ($self, $args) = @_;
    
    my $raw_event = $args->{'raw_event'};

    if ($self->Verbose())
    {
        chomp($raw_event);
        $self->output()->print_message($raw_event);
    }
}

sub _report_test_progress
{
    my ($self, $args) = @_;

    my $totals = $args->{totals};

    my $curr = $totals->seen();
    my $next = $self->Strap()->next();
    my $max  = $totals->max();
    my $detail = $totals->last_detail;

    if ( $detail->ok() )
    {
        $self->output()->print_ml_less("ok $curr/$max");
    }
    else
    {
        $self->output()->print_ml("NOK $curr");
    }

    if ($curr > $next) 
    {
        $self->output()->print_message("Test output counter mismatch [test $curr]");
    }
    elsif ($curr < $next)
    {
        $self->output()->print_message(
            "Confused test output: test $curr answered after test " . 
            ($next - 1)
        );
    }
}

sub _report_script_start_environment
{
    my $self = shift;

    if ( $self->Debug() )
    {
        my $perl5lib = 
            ((exists($ENV{PERL5LIB}) && defined($ENV{PERL5LIB})) ?
                $ENV{PERL5LIB} :
                ""
            );

        $self->output()->print_message("# PERL5LIB=$perl5lib");
    }
}

sub _report_could_not_run_script
{
    my ($self, $args) = @_;

    my $file = $args->{file};
    my $error = $args->{error};

    $self->output()->print_message("can't run $file. $error");
}

sub _handle_test_file_opening_error
{
    my ($self, $args) = @_;

    my $file = $args->{file};
    my $error = $args->{error};

    $self->output()->print_message("can't open $file. $error");
}

sub _handle_test_file_closing_error
{
    my ($self, $args) = @_;

    my $file = $args->{file};
    my $error = $args->{error};

    $self->output()->print_message("can't close $file. $error");
}

1;
