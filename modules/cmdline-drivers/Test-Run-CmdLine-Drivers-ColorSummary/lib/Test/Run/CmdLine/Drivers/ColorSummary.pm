package Test::Run::CmdLine::Drivers::ColorSummary;

use warnings;
use strict;

use vars qw(@ISA);

use Test::Run::Obj;
use Term::ANSIColor;

@ISA=(qw(Test::Run::Obj));

=head1 NAME

Test::Run::CmdLine::Drivers::ColorSummary - A Test::Run command line driver that
colors the summary.

=cut

our $VERSION = '0.0100_00';

=head1 SYNOPSIS

    $ TEST_HARNESS_DRIVER=Test::Run::CmdLine::Drivers::ColorSummary \ 
        runprove t/*.t

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 FUNCTIONS

=cut 

sub _report_success
{
    my $self = shift;
    print color("bold blue");
    $self->SUPER::_report_success();
    print color("reset");
}

=head2 $tester->runtests()

We override runtests() to colour the errors in red. The rest of the 
documentation is the code.

=cut

sub runtests
{
    my $self = shift;
    my $ret;
    eval
    {
        $ret = $self->SUPER::runtests();
    };
    if ($@)
    {
        print STDERR color("bold red");
        print STDERR $@;
        print STDERR color("reset");
        # Workaround to make sure color("reset") is accepted and a red cursor
        # is not displayed.
        print STDERR "\n";
    }
    else
    {
        return $ret;
    }
}

1;

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline-drivers-colorsummary@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine-Drivers-ColorSummary>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

1;

