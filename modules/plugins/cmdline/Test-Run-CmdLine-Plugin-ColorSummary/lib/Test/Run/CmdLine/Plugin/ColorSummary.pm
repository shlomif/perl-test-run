package Test::Run::CmdLine::Plugin::ColorSummary;

use warnings;
use strict;

use NEXT;

=head1 NAME

Test::Run::CmdLine::Plugin::ColorSummary - Color the summary in Test::Run::CmdLine.

=cut

our $VERSION = '0.0100_01';

sub _initialize
{
    my $self = shift;
    $self->NEXT::_initialize(@_);
    $self->add_to_backend_plugins("ColorSummary");
}

sub _get_backend_env_mapping
{
    my $self = shift;
    return
        [
        {
            'env' => "HARNESS_SUMMARY_COL_SUC",
            'arg' => "summary_color_success",
        },
        {
            'env' => "HARNESS_SUMMARY_COL_FAIL",
            'arg' => "summary_color_failure",
        },
        @{$self->NEXT::_get_backend_env_mapping()}
        ];
}
=head1 SYNOPSIS

This plug-in colors the summary line in Test::Run::CmdLine.

=head1 ENVIRONMENT VARIABLES

This module accepts the followinge environment variables:

=over 4

=item HARNESS_SUMMARY_COL_SUC

This specifies the Term::ANSIColor color for the success line.

=item HARNESS_SUMMARY_COL_FAIL

This specifies the Term::ANSIColor color for the failure line

=back

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

This program is released under the following license: MIT X11.

=cut

1;

