package Test::Run::Plugin::ColorSummary;

use warnings;
use strict;

use NEXT;
use Term::ANSIColor;

=head1 NAME

Test::Run::Plugin::ColorSummary - A Test::Run plugin that
colors the summary.

=cut

our $VERSION = '0.0100_00';

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

=head1 FUNCTIONS

=cut

sub _report_success
{
    my $self = shift;
    print color("bold blue");
    $self->NEXT::_report_success();
    print color("reset");
}

=head2 $tester->runtests()

We override runtests() to colour the errors in red. The rest of the 
documentation is the code.

=cut

sub _handle_runtests_error
{
    my $self = shift;
    my (%args) = @_;
    my $error = $args{'error'};

    print STDERR color("bold red");
    print STDERR $error;
    print STDERR color("reset");
    # Workaround to make sure color("reset") is accepted and a red cursor
    # is not displayed.
    print STDERR "\n";
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

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

