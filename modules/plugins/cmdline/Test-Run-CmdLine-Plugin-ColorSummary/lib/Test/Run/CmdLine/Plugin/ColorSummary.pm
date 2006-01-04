package Test::Run::CmdLine::Plugin::ColorSummary;

use warnings;
use strict;

use NEXT;

=head1 NAME

Test::Run::CmdLine::Plugin::ColorSummary - Color the summary in Test::Run::CmdLine.

=cut

our $VERSION = '0.0100_00';

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("ColorSummary");
}

=head1 SYNOPSIS

This plug-in colors the summary line in Test::Run::CmdLine.

=head1 FUNCTIONS

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline-plugin-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine-Plugin-ColorSummary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: BSD

=cut

1;

