package Test::Run::Plugin::FailSummaryComponents;

use warnings;
use strict;

use Moose;

use MRO::Compat;

use Scalar::Util ();

extends ("Test::Run::Base");

=head1 NAME

Test::Run::Plugin::FailSummaryComponents - A Test::Run plugin that
customizes the failure summary line.

=cut

our $VERSION = '0.0100_03';

my @params = (qw(
    failsumm_remove_test_scripts_number
    failsumm_remove_test_scripts_percent
    failsumm_remove_subtests_percent
));

has 'failsumm_remove_subtests_percent' => (is => "rw", isa => "Bool",);
has 'failsumm_remove_test_scripts_number' => (is => "rw", isa => "Bool",);
has 'failsumm_remove_test_scripts_percent' => (is => "rw", isa => "Bool",);

sub _get_private_simple_params
{
    my $self = shift;
    return [@params];
}


=head1 SYNOPSIS

    package MyTestRun;
    
    use vars qw(@ISA);

    @ISA = (qw(Test::Run::Plugin::FailSummaryComponents Test::Run::Obj));

    my $tester = MyTestRun->new(
        test_files => 
        [
            "t/sample-tests/one-ok.t",
            "t/sample-tests/several-oks.t"
        ],
        );

    $tester->runtests();

=head1 EXTRA PARAMETERS TO NEW

We accept three new named parameters to the new constructor:

=head2 failsumm_remove_test_scripts_number

If set, removes the $N-out-of-$N test scripts number from the failure line.

=head2 failsumm_remove_test_scripts_percent

If set, removes the percent of the test scripts that failed.

=head2 failsumm_remove_subtests_percent

If set, removes the percent of the subtests that failed.

=cut

sub _get_fail_test_scripts_string
{
    my $self = shift;

    if ($self->failsumm_remove_test_scripts_number())
    {
        return "test scripts";
    }
    else
    {
        return $self->next::method();
    }
}

sub _get_fail_tests_good_percent_string
{
    my $self = shift;
    if ($self->failsumm_remove_test_scripts_percent())
    {
        return "";
    }
    else
    {
        return $self->next::method();
    }
}

sub _get_sub_percent_msg
{
    my $self = shift;

    if (!$self->failsumm_remove_subtests_percent())
    {
        return $self->next::method();
    }

    my $tot = $self->tot();
    return sprintf(" %d/%d subtests failed.",
        $tot->max() - $tot->ok(), $tot->max(), 
        );
}


=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-failsummarycomponents@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-FailSummaryComponents>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Test::Run::Obj>, L<Test::Run::CmdLine::Plugin::FailSummaryComponents>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

1;
