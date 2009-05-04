package Test::Run::CmdLine::Prove;

use strict;
use warnings;

use base 'Test::Run::Base';

use MRO::Compat;

use mro "dfs";

use Test::Run::CmdLine::Iface;
use Getopt::Long;
use Pod::Usage 1.12;
use File::Spec;

use vars qw($VERSION);
$VERSION = "0.0100_05";

__PACKAGE__->mk_accessors(qw(
    arguments
    dry
    ext_regex
    ext_regex_string
    recurse
    shuffle
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

    my $tester = Test::Run::CmdLine::Prove->new({'args' => [@ARGV]});

    $tester->run();

=cut

sub _init
{
    my ($self, $args) = @_;

    $self->maybe::next::method($args);

    my $arguments = $args->{'args'};
    my $env_switches = $args->{'env_switches'};

    $self->arguments($arguments);

    local @ARGV = @$arguments;

    if (defined($env_switches))
    {
        unshift @ARGV, split(" ", $env_switches);
    }

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
    my @ext = ();
    my $recurse = 0;
    my $shuffle = 0;

    GetOptions(
        'b|blib' => \$blib,
        'd|debug' => \$debug,
        'D|dry' => \$dry,
        'h|help|?' => sub { $self->_usage(1); },
        'H|man' => sub { $self->_usage(2); },
        'I=s@' => \@includes,
        'l|lib' => \$lib,
        'perl=s' => \$interpreter,
        'r|recurse' => \$recurse,
        's|shuffle' => \$shuffle,
        # Always put -t and -T up front.
        't' => sub { unshift @switches, "-t"; }, 
        'T' => sub { unshift @switches, "-T"; }, 
        'timer' => \$timer,
        'v|verbose' => \$verbose,
        'V|version' => sub { $self->_print_version(); exit(0); },
        'ext=s@' => \@ext,
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
    $self->dry($dry);
    $self->recurse($recurse);
    $self->shuffle($shuffle);

    $self->_set_ext(\@ext);
    
    $self->arguments([@ARGV]);

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

=head2 $prove = Test::Run::CmdLine::Prove->new({'args' => [@ARGV], 'env_switches' => $env_switches});

Initializes a new object. C<'args'> is a keyed parameter that gives the
command line for the prove utility (as an array ref of strings). 

C<'env_switches'> is a keyed parameter that gives a string containing more 
arguments, or undef if not wanted.

=head2 $prove->run()

Runs the tests.

=cut

sub run
{
    my $self = shift;

    my $tests = $self->_get_test_files();

    if ($self->_should_run_tests($tests))
    {
        return $self->_actual_run_tests($tests);
    }
    else
    {
        return $self->_dont_run_tests($tests);
    }
}

sub _should_run_tests
{
    my ($self, $tests) = @_;

    return scalar(@$tests);
}

sub _actual_run_tests
{
    my ($self, $tests) = @_;

    my $method = $self->dry() ? "_dry_run" : "_wet_run";

    return $self->$method($tests);
}

sub _dont_run_tests
{
    return 0;
}

sub _wet_run
{
    my $self = shift;
    my $tests = shift;

    my $test_run =
        Test::Run::CmdLine::Iface->new(
            {
                'test_files' => [@$tests],
                'backend_params' => $self->_get_backend_params(),
            }
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
            $ret->{$key} = join(" ", @$value);
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

sub _usage
{
    my $self = shift;
    my $verbosity = shift;

    pod2usage(
        {
            '-verbose' => $verbosity, 
        }
    );
    exit(0);
}

sub _default_ext
{
    my $self = shift;
    my $ext = shift;
    return (@$ext ? $ext : ["t"]);
}

sub _normalize_extensions
{
    my $self = shift;

    my $ext = shift;
    $ext = [ map { split(/,/, $_) } @$ext ];
    foreach my $e (@$ext)
    {
        $e =~ s{^\.}{};
    }
    return $ext;
}

sub _set_ext
{
    my $self = shift;
    my $ext = $self->_default_ext(shift);

    $self->ext_regex_string('\.(?:' . 
        join("|", map { quotemeta($_) } 
            @{$self->_normalize_extensions($ext)}
        ) 
        . ')$'
    );
    $self->_set_ext_re();
}

sub _set_ext_re
{
    my $self = shift;
    my $s = $self->ext_regex_string();
    $self->ext_regex(qr/$s/);
}

sub _post_process_test_files_list
{
    my ($self, $list) = @_;
    if ($self->shuffle())
    {
        return $self->_perform_shuffle($list);
    }
    else
    {
        return $list;
    }
}

sub _perform_shuffle
{
    my ($self, $list) = @_;
    my @ret = @$list;
    my $i = @ret;
    while ($i)
    {
        my $place = int(rand($i--));
        @ret[$i,$place] = @ret[$place, $i];
    }
    return \@ret;
}

sub _get_arguments
{
    my $self = shift;
    my $args = $self->arguments();
    if (@$args)
    {
        return $args;
    }
    else
    {
        return [ File::Spec->curdir() ];
    }
}

sub _get_test_files
{
    my $self = shift;
    return 
        $self->_post_process_test_files_list(
            [ 
                map 
                { $self->_get_test_files_from_arg($_) } 
                @{$self->_get_arguments()} 
            ]
        );
}

sub _get_test_files_from_arg
{
    my ($self, $arg) = @_;
    return (map { $self->_get_test_files_from_globbed_entry($_) } glob($arg));
}

sub _get_test_files_from_globbed_entry
{
    my ($self, $entry) = @_;
    if (-d $entry)
    {
        return $self->_get_test_files_from_dir($entry);
    }
    else
    {
        return $self->_get_test_files_from_file($entry);
    }
}

sub _get_test_files_from_file
{
    my ($self, $entry) = @_;
    return ($entry);
}

sub _get_test_files_from_dir
{
    my ($self, $path) = @_;
    if (opendir my $dir, $path)
    {
        my @files = sort readdir($dir);
        closedir($dir);
        return 
            (map { $self->_get_test_files_from_dir_entry($path, $_) } @files);
    }
    else
    {
        warn "$path: $!\n";
        return ();
    }    
}

sub _should_ignore_dir_entry
{
    my ($self, $dir, $file) = @_;
    return
        (
            ($file eq File::Spec->updir()) || 
            ($file eq File::Spec->curdir()) ||
            ($file eq ".svn") ||
            ($file eq "CVS")
        );
}

sub _get_test_files_from_dir_entry
{
    my ($self, $dir, $file) = @_;
    if ($self->_should_ignore_dir_entry($dir, $file))
    {
        return ();
    }
    my $path = File::Spec->catfile($dir, $file);
    if (-d $path)
    {
        return $self->_get_test_files_from_dir_path($path);
    }
    else
    {
        return $self->_get_test_files_from_file_path($path);
    }
}

sub _get_test_files_from_dir_path
{
    my ($self, $path) = @_;
    if ($self->recurse())
    {
        return $self->_get_test_files_from_dir($path);
    }
    else
    {
        return ();
    }
}

sub _get_test_files_from_file_path
{
    my ($self, $path) = @_;
    if ($path =~ $self->ext_regex())
    {
        return ($path);
    }
    else
    {
        return ();
    }
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
