package Test::Run::CmdLine::Iface;

use warnings;
use strict;

extends ('Test::Run::Base');

use UNIVERSAL::require;

use Test::Run::CmdLine;

use Moose;

=head1 NAME

Test::Run::CmdLine::Iface - Analyze tests from the command line using Test::Run

=head1 SYNOPSIS

    use Test::Run::CmdLine::Iface;

    my $tester = Test::Run::CmdLine::Iface->new(
        {
            'test_files' => ["t/one.t", "t/two.t"],
        }
    );

    $tester->run();

=cut

has 'driver_class' => (is => "rw", isa => "Str");
has 'driver_plugins' => (is => "rw", isa => "ArrayRef");
has 'test_files' => (is => "rw", isa => "ArrayRef");
has 'backend_params' => (is => "rw", isa => "HashRef");
has '_is_driver_class_prepared' => (is => "rw", isa => "Bool");

sub _init
{
    my ($self, $args) = @_;

    $self->_is_driver_class_prepared(0);
    $self->driver_plugins([]);
    if ($args->{'driver_class'} || $args->{'driver_plugins'})
    {
        $self->_set_driver(
            {
                'class' => ($args->{'driver_class'} ||
                    "Test::Run::CmdLine::Drivers::Default"),
                'plugins' => ($args->{'driver_plugins'} || []),
            }
        );
    }
    elsif ($ENV{'HARNESS_DRIVER'} || $ENV{'HARNESS_PLUGINS'})
    {
        $self->_set_driver(
            {
                'class' => ($ENV{'HARNESS_DRIVER'} ||
                    "Test::Run::CmdLine::Drivers::Default"),
                'plugins' => [split(/\s+/, $ENV{'HARNESS_PLUGINS'} || "")]
            }
        );
    }
    else
    {
        $self->_set_driver(
            {
                'class' => "Test::Run::CmdLine::Drivers::Default",
                'plugins' => [],
            }
        );
    }
    
    $self->test_files($args->{'test_files'} || []);
    $self->_process_args($args);

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

=head2 $tester = Test::Run::CmdLine::Iface->new({'test_files' => \@test_files, ....});

Initializes a new testing front end. C<test_files> is a named argument that
contains the files to test.

Other named arguments are:

=over 4

=item backend_params

This is a hash of named parameters to be passed to the backend class (derived
from L<Test::Run::Obj>.)

=item driver_class

This is the backend class that will be instantiated and used to perform
the processing. Defaults to L<Test::Run::CmdLine::Drivers::Default>.

=item driver_plugins

This is a list of plugin classes to be used by the driver class. Each plugin
is a module and a corresponding class, that is prefixed by 
C<Test::Run::CmdLine::Plugin::> - a prefix which should not be included in
them.

=back

=head2 $tester->run()

Actually runs the tests on the command line.

TODO : Write more.
 
=cut

sub _real_prepare_driver_class
{
    my $self = shift;

    my $driver_class = $self->driver_class();
    $driver_class->require();
    if ($@)
    {
        die $@;
    }

    foreach my $plugin (@{$self->_calc_plugins_for_ISA()})
    {
        $plugin->require();
        if ($@)
        {
            die $@;
        }
        {
            no strict 'refs';
            push @{"${driver_class}::ISA"}, $plugin;
        }
    }

    # Finally - put Test::Run::CmdLine there.
    {
        no strict 'refs';
        push @{"${driver_class}::ISA"}, "Test::Run::CmdLine";
    }


}

# Does _real_prepare_driver_class with memoization.

sub _prepare_driver_class
{
    my $self = shift;

    if (! $self->_is_driver_class_prepared())
    {
        $self->_real_prepare_driver_class();

        $self->_is_driver_class_prepared(1);
    }
    return;
}

sub _calc_driver
{
    my $self = shift;

    $self->_prepare_driver_class();

    my $driver = $self->driver_class()->new(
        {
            'test_files' => $self->test_files(),
            'backend_params' => $self->backend_params(),
        }
    );

}
sub run
{
    my $self = shift;

    return $self->_calc_driver()->run();
}

sub _check_driver_class
{
    my $self = shift;
    return $self->_is_class_name(@_);
}

sub _check_plugins
{
    my $self = shift;
    my $plugins = shift;
    foreach my $p (@$plugins)
    {
        if (! $self->_is_class_name($p))
        {
            return 0;
        }
    }
    return 1;
}

sub _is_class_name
{
    my $self = shift;
    my $class = shift;
    return ($class =~ /^\w+(?:::\w+)*$/);
}

sub _set_driver
{
    my ($self, $args) = @_;

    my $class = $args->{'class'};
    if (! $self->_check_driver_class($class))
    {
        die "Invalid Driver Class \"$class\"!";
    }
    $self->driver_class($class);

    my $plugins = $args->{'plugins'};
    if (! $self->_check_plugins($plugins))
    {
        die "Invalid Plugins for Test::Run::CmdLine::Iface!";
    }
    $self->driver_plugins($plugins);

    return 0;
}

sub _calc_plugins_for_ISA
{
    my $self = shift;
    return 
        [ 
            map { $self->_calc_single_plugin_for_ISA($_) } 
            @{$self->driver_plugins()} 
        ];
}

sub _calc_single_plugin_for_ISA
{
    my $self = shift;
    my $p = shift;

    return "Test::Run::CmdLine::Plugin::$p";
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
