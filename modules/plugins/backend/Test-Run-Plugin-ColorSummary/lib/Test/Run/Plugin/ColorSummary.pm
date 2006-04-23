package Test::Run::Plugin::ColorSummary;

use warnings;
use strict;

use NEXT;
use Term::ANSIColor;
use Scalar::Util ();

use base 'Test::Run::Base';
use base 'Class::Accessor';

=head1 NAME

Test::Run::Plugin::ColorSummary - A Test::Run plugin that
colors the summary.

=cut

our $VERSION = '0.0100_02';

__PACKAGE__->mk_accessors(qw(
    summary_color_failure
    summary_color_success
));

sub _get_simple_params
{
    my $self = shift;
    return 
    [
        qw(summary_color_failure summary_color_success), 
        @{$self->NEXT::_get_simple_params()}
    ];
}

sub _get_failure_summary_color
{
    my $self = shift;
    return $self->summary_color_failure() || 
        $self->_get_default_failure_summary_color();
}

sub _get_default_failure_summary_color
{
    return "bold red";
}

sub _get_success_summary_color
{
    my $self = shift;
    return $self->summary_color_success() || 
        $self->_get_default_success_summary_color();
}

sub _get_default_success_summary_color
{
    return "bold blue";
}

=head1 SYNOPSIS

    package MyTestRun;
    
    use vars qw(@ISA);

    @ISA = (qw(Test::Run::Plugin::ColorSummary Test::Run::Obj));

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

sub _report_success
{
    my $self = shift;
    print color($self->_get_success_summary_color());
    $self->NEXT::_report_success();
    print color("reset");
}

=head2 $tester->_handle_runtests_error()

We override _handle_runtests_error() to colour the errors in red. The rest of
the documentation is the code.

=cut

sub _handle_runtests_error_text
{
    my $self = shift;
    my (%args) = @_;
    my $text = $args{'text'};

    print STDERR color($self->_get_failure_summary_color());
    print STDERR $text;
    print STDERR color("reset");
    # Workaround to make sure color("reset") is accepted and a red cursor
    # is not displayed.
    print STDERR "\n";
    die "\n";
}

1;

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-ColorSummary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Test::Run::Obj>, L<Term::ANSIColor>, 
L<Test::Run::CmdLine::Plugin::ColorSummary>.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

