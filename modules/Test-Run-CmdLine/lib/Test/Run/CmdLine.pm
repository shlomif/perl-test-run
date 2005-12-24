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

    use Test::Run::CmdLine;

    my $tester = Test::Run::CmdLine->new(
        'test_files' => ["t/one.t", "t/two.t"],
    );

    $tester->run();

=cut

__PACKAGE__->mk_accessors(qw(
    driver_class
    test_files
    backend_params
));

sub _initialize
{
    my $self = shift;
    my (%args) = @_;
    my $driver_class = $args{'driver_class'} || $ENV{'TEST_HARNESS_DRIVER'} ||
        "Test::Run::Obj";
    $self->_set_driver_class($driver_class);
    $self->test_files($args{'test_files'});
    $self->_process_args(\%args);

    return 0;
}

sub _process_args
{
    my ($self, $args) = @_;
    if (exists($args->{backend_params}))
    {
        $self->backend_params($args->{backend_params});
    }

    return 0;
}

=head1 Interface Functions

=head2 $tester = Test::Run::CmdLine->new('test_files' => \@test_files, ....);

Initializes a new testing front end. C<test_files> is a named argument that
contains the files to test.

Other named arguments are:

=over 4

=item backend_params

This is a hash of named parameters to be passed to the backend class (derived
from L<Test::Run::Obj>.)

=item driver_class

This is the backend class that will be instantiated and used to perform
the processing. Defaults to L<Test::Run::Obj>.

=back 

=head2 $tester->run()

Actually runs the tests on the command line.

TODO : Write more.

=cut

sub run
{
    my $self = shift;
    my $driver_class = $self->driver_class();
    eval "require $driver_class";

    my $back_end_args = $self->get_backend_args();

    my $driver = $driver_class->new(
        'test_files' => $self->test_files(),
        @$back_end_args,
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

=head1 Environment Variables

The following environment variables (C<%ENV>) affect the behaviour of 
Test::Run::CmdLine:

=over 4

=item HARNESS_FILELEAK_IN_DIR

This variable points to a directory that will be monitored. After each
test file, the module will check if new files appeared in the direcotry
and report them. 
    
It is advisable to give an absolute path here. If it is relative, it would
be relative to the current working directory when C<$tester-E<gt>run()> was
called.

=item HARNESS_VERBOSE

Triggers the C<'Verbose'> option in Test::Run::Obj. Meaning, it emits 
the standard output of the test files while they are processed.

=back

=head1 Internal Functions

=head2 my $args_array_ref = $tester->get_backend_args()

Calculate and retrieve the arguments for the backend class (that inherits
from L<Test::Run::Obj>) as a single array reference. Currently it appends
the arguments of get_backend_env_args() to that of get_backend_init_args().

=cut

sub get_backend_args
{
    my $self = shift;

    my $env_var_args = $self->get_backend_env_args();

    my $init_args = $self->get_backend_init_args();

    return [@$env_var_args, @$init_args,];
}

=head2 my $args_array_ref = $tester->get_backend_env_args()

Calculate and return the arguments for the backend class, that originated
from the environment (%ENV).

=cut

sub get_backend_env_args
{
    my $self = shift;
    my @args;
    if (exists($ENV{HARNESS_FILELEAK_IN_DIR}))
    {
        push @args, ('Leaked_Dir' => $ENV{HARNESS_FILELEAK_IN_DIR});
    }
    if (exists($ENV{HARNESS_VERBOSE}))
    {
        push @args, ('Verbose' => $ENV{HARNESS_VERBOSE});
    }
    return \@args;
}

=head2 my $args_array_ref = $tester->get_backend_init_args()

Calculate and return the arguments for the backend class, that originated
from the arguments passed to the (front-end) object from its constructor.

=cut

sub get_backend_init_args
{
    my $self = shift;
    my @args;
    if (defined($self->backend_params()))
    {
        push @args, (%{$self->backend_params()});
    }
    return \@args;
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
