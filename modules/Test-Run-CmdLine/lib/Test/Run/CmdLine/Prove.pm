package Test::Run::CmdLine::Prove;

use strict;
use warnings;

use base 'Test::Run::Base';

use Test::Run::CmdLine::Iface;
use Getopt::Long;
use Pod::Usage 1.12;
use File::Spec;

use vars qw($VERSION);
$VERSION = "0.0100_05";

__PACKAGE__->mk_accessors(qw(
    Verbose
    Debug
    Switches
    Test_Interpreter
    Timer
));
=head1 NAME

Test::Run::CmdLine::Prove - A Module for running tests from the command line

=head1 SYNOPSIS

    use Test::Run::CmdLine::Prove;

    my $tester = Test::Run::CmdLine::Prove->new();

    $tester->run();

=cut

sub _initialize
{
    return 0;
}

sub _include_map
{
    my $self = shift;
    my $arg = shift;
    my $ret = "-I$arg";
    if (($arg =~ /\s/) && 
        (! (($arg =~ /^"/) && ($arg =~ /"$/)) ) 
       )
    {
        return "\"$ret\"";
    }
    else
    {
        return $ret;
    }
}

sub _print_version
{
    my $self = shift;
    printf("runprove v%s, using Test::Run v%s, Test::Run::CmdLine v%s and Perl v%s\n",
        $VERSION,
        $Test::Run::Obj::VERSION,
        $Test::Run::CmdLine::VERSION,
        $^V
    );
}

=head1 Interface Functions

=head2 $prove = Test::Run::CmdLine::Prove->new();

Initializes a new object.

=head2 $prove->run()

Implements the runprove utility and runs it.

=cut

sub run
{
    my $self = shift;

    # Allow a -I<path> switch instead of -I <path>
    @ARGV = (map { /^-I(.+)/ ? ("-I", $1) : ($_) } @ARGV);

    Getopt::Long::Configure( "no_ignore_case" );
    Getopt::Long::Configure( "bundling" );

    my $verbose = undef;
    my $debug = undef;
    my $timer = undef;
    my $interpreter = undef;
    my @switches = ();
    my @includes = ();
    my $blib = 0;
    my $lib = 0;
    my $dry = 0;

    GetOptions(
        'b|blib' => \$blib,
        'd|debug' => \$debug,
        'D|dry' => \$dry,
        'I=s@' => \@includes,
        'l|lib' => \$lib,
        'perl=s' => \$interpreter,
        # Always put -t and -T up front.
        't' => sub { unshift @switches, "-t"; }, 
        'T' => sub { unshift @switches, "-T"; }, 
        'timer' => \$timer,
        'v|verbose' => \$verbose,
        'V|version' => sub { $self->_print_version(); exit(0); },
    );

    if ($blib)
    {
        unshift @includes, ($self->_blibdirs());
    }

    # Handle the lib include path
    if ($lib)
    {
        unshift @includes, "lib";
    }

    push @switches, (map { $self->_include_map($_) } @includes);

    $self->Verbose($verbose);
    $self->Debug($debug);
    $self->Switches(\@switches);
    $self->Test_Interpreter($interpreter);
    $self->Timer($timer);

    my @tests = @ARGV;

    if ($dry)
    {
        return $self->_dry_run(\@tests);
    }
    else
    {
        return $self->_wet_run(\@tests);
    }
}

sub _wet_run
{
    my $self = shift;
    my $tests = shift;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            'test_files' => [@$tests],
            'backend_params' => $self->_get_backend_params(),
        );

    return $test_run->run();
}

sub _dry_run
{
    my $self = shift;
    my $tests = shift;
    print join("\n", @$tests, "");
    return 0;
}

# Stolen directly from blib.pm
sub _blibdirs {
    my $self = shift;
    my $dir = File::Spec->curdir;
    if ($^O eq 'VMS') {
        ($dir = VMS::Filespec::unixify($dir)) =~ s-/\z--;
    }
    my $archdir = "arch";
    if ( $^O eq "MacOS" ) {
        # Double up the MP::A so that it's not used only once.
        $archdir = $MacPerl::Architecture = $MacPerl::Architecture;
    }

    my $i = 5;
    while ($i--) {
        my $blib      = File::Spec->catdir( $dir, "blib" );
        my $blib_lib  = File::Spec->catdir( $blib, "lib" );
        my $blib_arch = File::Spec->catdir( $blib, $archdir );

        if ( -d $blib && -d $blib_arch && -d $blib_lib ) {
            return ($blib_arch,$blib_lib);
        }
        $dir = File::Spec->catdir($dir, File::Spec->updir);
    }
    warn "Could not find blib dirs";
    return;
}

sub _get_backend_params_keys
{
    return [qw(Verbose Debug Timer Test_Interpreter Switches)];
}

sub _get_backend_params
{
    my $self = shift;
    my $ret = +{};
    foreach my $key (@{$self->_get_backend_params_keys()})
    {
        my $value = $self->get($key);
        if (ref($value) eq "ARRAY")
        {
            if (@$value)
            {
                $ret->{$key} = join(" ", @$value);
            }
        }
        else
        {
            if (defined($value))
            {
                $ret->{$key} = $value;
            }
        }
    }
    return $ret;
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

1;
