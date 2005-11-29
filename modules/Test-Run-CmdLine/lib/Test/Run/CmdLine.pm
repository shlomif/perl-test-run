package Test::Run::CmdLine;

use warnings;
use strict;

use Test::Run::Base;

=head1 NAME

Test::Run::CmdLine - Analyze tests from the command line using Test::Run

=cut

use vars (qw($VERSION));

$VERSION = '0.0100_01';

use vars (qw(@ISA));

@ISA = (qw(Test::Run::Base));

=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Test::Run::CmdLine;

    my $foo = Test::Run::CmdLine->new();
    ...
=cut

__PACKAGE__->mk_accessors(qw(
    driver_class
    test_files
));

sub _initialize
{
    my $self = shift;
    my (%args) = @_;
    my $driver_class = $args{'driver_class'} || $ENV{'TEST_HARNESS_DRIVER'} ||
        "Test::Run::Obj";
    $self->_set_driver_class($driver_class);
    $self->test_files($args{'test_files'});
}

=head2 $cmd_line->run()

Actually runs the test on the command line.

TODO : Write more.

=cut

sub run
{
    my $self = shift;
    my $driver_class = $self->driver_class();
    eval "require $driver_class";

    my $driver = $driver_class->new(
        'test_files' => $self->test_files(),
    );

    return $driver->runtests();
}

sub _check_driver_class
{
    my $self = shift;
    return $self->_is_class_name(@_);
}

sub _is_class_name
{
    my $self = shift;
    my $class = shift;
    return ($class =~ /^\w+(?:::\w+)*$/);
}

sub _set_driver_class
{
    my $self = shift;
    my $driver_class = shift;
    if (! $self->_check_driver_class($driver_class))
    {
        die "Invalid Driver Class \"$driver_class\"!";
    }
    $self->driver_class($driver_class);
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-cmdline@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-CmdLine>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Shlomi Fish, all rights reserved.

This program is released under the MIT X11 License.

=cut

1; # End of Test::Run::CmdLine
