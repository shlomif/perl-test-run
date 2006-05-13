package Test::Run::Plugin::FailSummaryComponents;

use warnings;
use strict;

use NEXT;
use Scalar::Util ();

use base 'Test::Run::Base';
use base 'Class::Accessor';

=head1 NAME

Test::Run::Plugin::FailSummaryComponents - A Test::Run plugin that
customizes the failure summary line.

=cut

our $VERSION = '0.0100_02';

my @params = (qw(
    failsumm_remove_test_scripts_number
    failsumm_remove_test_scripts_percent
    failsumm_remove_subtests_percent
));

__PACKAGE__->mk_accessors(
    @params
);

sub _get_simple_params
{
    my $self = shift;
    return 
    [
        @params,
        @{$self->NEXT::_get_simple_params()}
    ];
}

sub _get_fail_test_scripts_string
{
    my $self = shift;

    if ($self->failsumm_remove_test_scripts_number())
    {
        return "test scripts";
    }
    else
    {
        return $self->NEXT::_get_fail_test_scripts_string();
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
        return $self->NEXT::_get_fail_tests_good_percent_string();
    }
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

We accept two new named parameters to the new constructor:

=head2 summary_color_success

This is the color string for coloring the success line. The string itself
conforms to the one specified in L<Term::ANSIColor>.

=head2 summary_color_failure

This is the color string for coloring the summary line in case of
failure. The string itself conforms to the one specified 
in L<Term::ANSIColor>.

=head1 FUNCTIONS

=cut

1;

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-FailSummaryComponents>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Test::Run::Obj>, L<Test::Run::CmdLine::Plugin::FailSummaryComponents>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

