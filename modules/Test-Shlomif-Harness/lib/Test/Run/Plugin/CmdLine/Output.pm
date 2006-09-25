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

1;
