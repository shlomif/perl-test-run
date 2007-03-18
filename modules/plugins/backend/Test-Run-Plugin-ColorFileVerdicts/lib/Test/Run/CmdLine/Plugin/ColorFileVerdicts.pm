package Test::Run::CmdLine::Plugin::ColorFileVerdicts;

use strict;
use warnings;

use NEXT;

=head1 NAME

Test::Run::CmdLine::Plugin::ColorFileVerdicts - Color the individual test file
verdicts in Test::Run::CmdLine.

=head1 VERSION

0.01

=head1 METHODS

=cut

our $VERSION = '0.01';

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("ColorFileVerdicts");
}

=head2 $self->get_backend_args()

Over-rides the L<Test::Run::CmdLine> method to process the 
C<PERL_HARNESS_VERDICT_COLORS> environment variable.

=cut

sub get_backend_args
{
    my $self = shift;

    return [@{$self->NEXT::get_backend_args()}, $self->_get_file_verdicts_color_mappings()];
}

sub _get_file_verdicts_color_mappings
{
    my $self = shift;

    if (exists($ENV{PERL_HARNESS_VERDICT_COLORS}))
    {
        # FIXME 
        # Do something
        return ();
    }
    else
    {
        return ();
    }
}

=head1 SEE ALSO

L<Test::Run::CmdLine>, L<Test::Run::CmdLine::Plugin::ColorSummary>.

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-colorfileverdicts at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-ColorFileVerdicts>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::ColorFileVerdicts

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Run-Plugin-ColorFileVerdicts>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Run-Plugin-ColorFileVerdicts>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Run-Plugin-ColorFileVerdicts>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Run-Plugin-ColorFileVerdicts>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11

=cut

