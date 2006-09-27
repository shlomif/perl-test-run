package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

=head1 Test::Run::Plugin::CmdLine::Output

This a module that implements the command line/STDOUT specific output of 
L<Test::Run::Obj>, which was taken out of L<Test::Run::Core> to increase
modularity.

=cut

use vars qw(@ISA);

@ISA=(qw(Test::Run::Core));

sub _report_dubious
{
    my ($self, $args) = @_;
    my $test = $args->{test_struct};
    my $estatus = $args->{estatus};

    $self->output()->print_message(
        sprintf($test->ml()."dubious\n\tTest returned status $estatus ".
            "(wstat %d, 0x%x)",
            (($args->{'wstatus'}) x 2))
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
    my ($self, $args) = @_;

    my $test = $args->{test_struct};

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

    my $test = $args->{test_struct};

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
    my ($self, $args) = @_;
    return
    [
        @{$self->_get_skipped_msgs($args)}, 
        @{$self->_get_bonus_msgs($args)}
    ];
}

sub _report_skipped_test
{
    my ($self, $args) = @_;

    my $test = $args->{test_struct};
    my $elapsed = $args->{elapsed};

    $self->output()->print_message(
        $test->ml()."ok$elapsed\n        ".
        join(', ', @{$self->_get_all_skipped_test_msgs($args)})
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

    my $test = $args->{test_struct};
    my $elapsed = $args->{elapsed};

    $self->output()->print_message($test->ml()."ok$elapsed");

    return;
}

sub _report_all_skipped_test
{
    my ($self, $args) = @_;

    my $test = $args->{test_struct};

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

1;
