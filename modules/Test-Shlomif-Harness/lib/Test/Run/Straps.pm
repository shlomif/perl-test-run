# -*- Mode: cperl; cperl-indent-level: 4 -*-
package Test::Run::Straps;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '0.24';

use Config;
use TAPx::Parser;
use List::Util qw(first);

use Test::Run::Base;
use Test::Run::Assert;
use TAPx::Parser;
use Test::Run::Obj::Structs;

@ISA = (qw(Test::Run::Base::Struct));

my @fields= (qw(
    bailout_reason
    callback
    Debug
    error
    _event
    file
    _file_totals
    _is_macos
    _is_vms
    _is_win32
    last_test_print
    line
    lone_not_line
    max
    next
    _old5lib
    output
    _parser
    saw_bailout
    saw_header
    skip_all
    Switches
    Switches_Env
    Test_Interpreter
    todo
    too_many_tests
    totals
    Verbose
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

# Flags used as return values from our methods.  Just for internal 
# clarification.
my $YES   = (1==1);
my $NO    = !$YES;

=head1 NAME

Test::Run::Straps - detailed analysis of test results

=head1 SYNOPSIS

  use Test::Run::Straps;

  my $strap = Test::Run::Straps->new;

  # Various ways to interpret a test
  my %results = $strap->analyze($name, \@test_output);
  my %results = $strap->analyze_fh($name, $test_filehandle);
  my %results = $strap->analyze_file($test_file);

  # UNIMPLEMENTED
  my %total = $strap->total_results;

  # Altering the behavior of the strap  UNIMPLEMENTED
  my $verbose_output = $strap->dump_verbose();
  $strap->dump_verbose_fh($output_filehandle);


=head1 DESCRIPTION

B<THIS IS ALPHA SOFTWARE> in that the interface is subject to change
in incompatible ways.  It is otherwise stable.

Test::Run is limited to printing out its results.  This makes
analysis of the test results difficult for anything but a human.  To
make it easier for programs to work with test results, we provide
Test::Run::Straps.  Instead of printing the results, straps
provide them as raw data.  You can also configure how the tests are to
be run.

The interface is currently incomplete.  I<Please> contact the author
if you'd like a feature added or something change or just have
comments.

=head1 CONSTRUCTION

=head2 new()

  my $strap = Test::Run::Straps->new;

Initialize a new strap.

=cut

sub _initialize {
    my $self = shift;
    my $args = shift;

    $self->_is_vms( $^O eq 'VMS' );
    $self->_is_win32( $^O =~ /^(MS)?Win32$/ );
    $self->_is_macos( $^O eq 'MacOS' );

    $self->output($args->{output}); 
    $self->totals(+{});
    $self->todo(+{});
}

=head1 ANALYSIS

=head2 $strap->analyze( $name, \@output_lines )

    my $results = $strap->analyze($name, \@test_output);

Analyzes the output of a single test, assigning it the given C<$name>
for use in the total report.  Returns the C<$results> of the test (an object).
See L<Results>.

C<@test_output> should be the raw output from the test, including
newlines.

=cut

sub _create_parser
{
    my ($self, $source) = @_;
    return TAPx::Parser->new(
            {
                source => $source,
            }
        );
}

sub analyze
{
    my($self, $name, $test_output_orig) = @_;

    $self->_parser($self->_create_parser($test_output_orig));

    return
        $self->_analyze_with_parser(
            $name,
        );
}

sub _init_totals_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsTotalsObj->new($args);
}

sub _init_details_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsDetailsObj->new($args);
}

sub _get_initial_totals_obj_params
{
    return
    {
        max      => 0,
        seen     => 0,

        ok       => 0,
        todo     => 0,
        skip     => 0,
        bonus    => 0,

        details  => [],
    };
}

sub _start_new_file
{
    my $self = shift;
    my $name = shift;

    $self->_reset_file_state;
    $self->file($name);
    my $totals =
        $self->_init_totals_obj_instance(
            $self->_get_initial_totals_obj_params(),
        );

    $self->_file_totals($totals);

    # Set them up here so callbacks can have them.
    $self->totals()->{$name}         = $totals;

    return;
}

sub _get_next_event
{
    my ($self) = @_;

    return $self->_event(scalar($self->_parser->next()));
}

sub _end_file
{
    my $self = shift;

    $self->_parser(undef);
    $self->_event(undef);

    return;
}

sub _analyze_with_parser {
    my($self, $name) = @_;

    $self->_start_new_file($name);

    while ($self->_get_next_event())
    {
        $self->_analyze_event();
        last if $self->saw_bailout();
    }

    $self->_file_totals->determine_passing();

    $self->_end_file($name);

    return $self->_file_totals;
}

sub _handle_callback
{
    my $self = shift;

    if ($self->callback())
    {
        $self->callback()->(
            $self, 
            {
                event => $self->_event(),
                totals => $self->_file_totals(),
            }
        );
    }
}

sub _bump_next
{
    my $self = shift;

    if ($self->_event->is_test())
    {
        $self->next($self->_event->number + 1) 
    }
}

# TODO : Maybe we just need has_todo() here.
sub _is_event_todo
{
    my $self = shift;
    
    my $event = $self->_event;

    return
    ( 
        $event->has_todo() || 
        (first { $_ == $event->number() } $self->_parser->todo())
    );
}

sub _is_event_pass
{
    my $self = shift;

    return 
    (
        $self->_event->passed() ||
        $self->_is_event_todo() ||
        $self->_event->has_skip()
    );
}

sub _update_details
{
    my $self = shift;

    my $event = $self->_event;

    my $details =
        $self->_init_details_obj_instance(
            {
                ok          => $self->_is_event_pass(),
                actual_ok   => scalar($event->passed),
                name        => _def_or_blank( $event->description ),
                # $event->directive returns "SKIP" or "TODO" in uppercase
                # and we expect them to be in lowercase.
                type        => lc(_def_or_blank( $event->directive )),
                reason      => _def_or_blank( $event->explanation ),
            },
        );

    assert( defined( $details->ok() ) && defined( $details->actual_ok() ) );
    $self->_file_totals->details()->[$event->number - 1] = $details;

    return;
}

sub _handle_comment
{
    my $self = shift;

    my $test = $self->_file_totals->details()->[-1];
    if (defined($test))
    {
        $test->append_to_diag($self->_event->comment());
    }

    return;
}

sub _analyze_event
{
    my $self = shift;
    
    my $event = $self->_event;

    my $totals = $self->_file_totals();

    $self->inc_field('line');

    # TODO : Refactor
    if ($event->is_test())
    {
        $totals->inc_field('seen');
        # TODO : Remove the commented line later
        # $point->set_number( $self->next()) unless $point->number;

        if ($self->_is_event_todo())
        {
            $totals->inc_field('todo');
            if ( $event->actual_passed() )
            {
                $totals->inc_field('bonus');
            }
        }
        elsif ( $event->has_skip ) {
            $totals->inc_field('skip');
        }

        if ($self->_is_event_pass())
        {
            $totals->inc_field('ok');
        }

        if ( ($event->number > 100_000) &&
             ($event->number > ($self->max()||100_000)) 
           )
        {
            if ( !$self->too_many_tests() )
            {
                warn "Enormous test number seen [test ", $event->number, "]\n";
                warn "Can't detailize, too big.\n";
                $self->too_many_tests(1);
            }
        }
        else
        {
            $self->_update_details();
        }
    } # test point
    elsif ( $event->is_plan() )
    {
        $self->inc_field('saw_header');
        $totals->max($event->tests_planned());
        # If it's a skip line.
        if ($event->tests_planned() == 0)
        {
            $totals->skip_all($event->explanation());
        }
    }
    elsif ( $event->is_bailout() )
    {
        $self->bailout_reason($event->explanation());
        $self->saw_bailout(1);
    }
    elsif ( $event->is_comment() )
    {
        $self->_handle_comment();
    }

    $self->_handle_callback();
    $self->_bump_next();
} # _analyze_line

=head2 $strap->analyze_fh( $name, $test_filehandle )

    my $results = $strap->analyze_fh($name, $test_filehandle);

Like C<analyze>, but it reads from the given filehandle.

=cut

sub analyze_fh
{
    my $self = shift;
    # The same as analyze due to TAPx::Parser polymorphism
    return $self->analyze(@_);
}

=head2 $strap->analyze_file( $test_file )

    my %results = $strap->analyze_file($test_file);

Like C<analyze>, but it runs the given C<$test_file> and parses its
results.  It will also use that name for the total report.

=cut

sub analyze_file {
    my($self, $file) = @_;

    unless( -e $file ) {
        $self->error("$file does not exist");
        return;
    }

    unless( -r $file ) {
        $self->error("$file is not readable");
        return;
    }

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;
    if ( $self->Debug() ) {
        local $^W=0; # ignore undef warnings
        $self->output()->print_message("# PERL5LIB=$ENV{PERL5LIB}");
    }

    # *sigh* this breaks under taint, but open -| is unportable.
    my $line = $self->_command_line($file);

    my $file_handle;
    unless ( open($file_handle, "$line|" )) {
        $self->output()->print_message("can't run $file. $!");
        return;
    }

    my $results;
    eval {
    $results = $self->analyze_fh($file, $file_handle);
    };
    my $error = $@;
    my $exit    = close ($file_handle);
    if ($error ne "")
    {
        die $error;
    }

    $results->wait($?);
    if( $? && $self->_is_vms() ) {
        eval q{use vmsish "status"; $results{'exit'} = $?};
    }
    else {
        $results->exit(_wait2exit($?));
    }
    $results->passing(0) unless $? == 0;

    $self->_restore_PERL5LIB();

    return $results;
}


eval { require POSIX; &POSIX::WEXITSTATUS(0) };
if( $@ ) {
    *_wait2exit = sub { $_[0] >> 8 };
}
else {
    *_wait2exit = sub { POSIX::WEXITSTATUS($_[0]) }
}

=head2 $strap->_command_line( $file )

Returns the full command line that will be run to test I<$file>.

=cut

sub _command_line {
    my $self = shift;
    my $file = shift;

    my $command =  $self->_command();
    my $switches = $self->_switches($file);

    $file = qq["$file"] if ($file =~ /\s/) && ($file !~ /^".*"$/);
    my $line = "$command $switches $file";

    return $line;
}


=head2 $strap->_command()

Returns the command that runs the test.  Combine this with C<_switches()>
to build a command line.

Typically this is C<$^X>, but you can set C<$self->Test_Interpreter()>
to use a different Perl than what you're running the harness under.
This might be to run a threaded Perl, for example.

You can also overload this method if you've built your own strap subclass,
such as a PHP interpreter for a PHP-based strap.

=cut

sub _command {
    my $self = shift;

    return $self->Test_Interpreter()    if defined $self->Test_Interpreter();
    return Win32::GetShortPathName($^X) if $self->_is_win32();
    return $^X;
}


=head2 $strap->_switches( $file )

Formats and returns the switches necessary to run the test.

=cut

sub _switches {
    my($self, $file) = @_;

    # my @existing_switches = $self->_cleaned_switches( $Test::Run::Obj::Switches, $ENV{HARNESS_PERL_SWITCHES} );
    my @existing_switches = $self->_cleaned_switches( $self->Switches(), $self->Switches_Env());
    my @derived_switches;

    local *TEST;
    open(TEST, $file) or $self->output()->print_message("can't open $file. $!");
    my $shebang = <TEST>;
    close(TEST) or $self->output()->print_message("can't close $file. $!");

    my $taint = ( $shebang =~ /^#!.*\bperl.*\s-\w*([Tt]+)/ );
    push( @derived_switches, "-$1" ) if $taint;

    # When taint mode is on, PERL5LIB is ignored.  So we need to put
    # all that on the command line as -Is.
    # MacPerl's putenv is broken, so it will not see PERL5LIB, tainted or not.
    if ( $taint || $self->_is_macos() ) {
	my @inc = $self->_filtered_INC;
	push @derived_switches, map { "-I$_" } @inc;
    }

    # Quote the argument if there's any whitespace in it, or if
    # we're VMS, since VMS requires all parms quoted.  Also, don't quote
    # it if it's already quoted.
    for ( @derived_switches ) {
	$_ = qq["$_"] if ((/\s/ || $self->_is_vms()) && !/^".*"$/ );
    }
    return join( " ", @existing_switches, @derived_switches );
}

=head2 $strap->_cleaned_switches( @switches_from_user )

Returns only defined, non-blank, trimmed switches from the parms passed.

=cut

sub _cleaned_switches {
    my $self = shift;

    local $_;

    my @switches;
    for ( @_ ) {
	my $switch = $_;
	next unless defined $switch;
	$switch =~ s/^\s+//;
	$switch =~ s/\s+$//;
	push( @switches, $switch ) if $switch ne "";
    }

    return @switches;
}

=head2 $strap->_INC2PERL5LIB

  local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;

Takes the current value of C<@INC> and turns it into something suitable
for putting onto C<PERL5LIB>.

=cut

sub _INC2PERL5LIB {
    my($self) = shift;

    $self->_old5lib($ENV{PERL5LIB});

    return join $Config{path_sep}, $self->_filtered_INC;
}

=head2 $strap->_filtered_INC()

  my @filtered_inc = $self->_filtered_INC;

Shortens C<@INC> by removing redundant and unnecessary entries.
Necessary for OSes with limited command line lengths, like VMS.

=cut

sub _filtered_INC {
    my($self, @inc) = @_;
    @inc = @INC unless @inc;

    if( $self->_is_vms() ) {
	# VMS has a 255-byte limit on the length of %ENV entries, so
	# toss the ones that involve perl_root, the install location
        @inc = grep !/perl_root/i, @inc;

    }
    elsif ( $self->_is_win32() ) {
	# Lose any trailing backslashes in the Win32 paths
	s/[\\\/+]$// foreach @inc;
    }

    my %seen;
    $seen{$_}++ foreach $self->_default_inc();
    @inc = grep !$seen{$_}++, @inc;

    return @inc;
}


sub _default_inc {
    my $self = shift;

    local $ENV{PERL5LIB};
    my $perl = $self->_command;
    my @inc =`$perl -le "print join qq[\\n], \@INC"`;
    chomp @inc;
    return @inc;
}


=head2 $strap->_restore_PERL5LIB()

  $self->_restore_PERL5LIB;

This restores the original value of the C<PERL5LIB> environment variable.
Necessary on VMS, otherwise a no-op.

=cut

sub _restore_PERL5LIB {
    my($self) = shift;

    return unless $self->_is_vms();

    if (defined $self->_old5lib()) {
        $ENV{PERL5LIB} = $self->_old5lib();
    }
}

=head1 Parsing

Methods for identifying what sort of line you're looking at.

=head2 C<_reset_file_state>

  $strap->_reset_file_state;

Resets things like C<< $strap->{max} >> , C<< $strap->{skip_all} >>,
etc. so it's ready to parse the next file.

=cut

sub _reset_file_state {
    my($self) = shift;

    delete @{$self}{qw(max skip_all too_many_tests)};
    $self->todo(+{});
    
    foreach my $field (qw(line saw_header saw_bailout lone_not_line))
    {
        $self->set($field, 0);
    }
    $self->bailout_reason('');
    $self->next(1);
}

=head1 Results

The C<%results> returned from C<analyze()> contain the following
information:

  passing           true if the whole test is considered a pass 
                    (or skipped), false if its a failure

  exit              the exit code of the test run, if from a file
  wait              the wait code of the test run, if from a file

  max               total tests which should have been run
  seen              total tests actually seen
  skip_all          if the whole test was skipped, this will 
                      contain the reason.

  ok                number of tests which passed 
                      (including todo and skips)

  todo              number of todo tests seen
  bonus             number of todo tests which 
                      unexpectedly passed

  skip              number of tests skipped

So a successful test should have max == seen == ok.


There is one final item, the details.

  details           an array ref reporting the result of 
                    each test looks like this:

    $results{details}[$test_num - 1] = 
            { ok          => is the test considered ok?
              actual_ok   => did it literally say 'ok'?
              name        => name of the test (if any)
              diagnostics => test diagnostics (if any)
              type        => 'skip' or 'todo' (if any)
              reason      => reason for the above (if any)
            };

Element 0 of the details is test #1.  I tried it with element 1 being
#1 and 0 being empty, this is less awkward.

=head1 EXAMPLES

See F<examples/mini_harness.plx> for an example of use.

=head1 AUTHOR

Michael G Schwern C<< <schwern@pobox.com> >>, later maintained by
Andy Lester C<< <andy@petdance.com> >>.

Converted to Test::Run::Straps by Shlomi Fish 
C<< <shlomif@iglu.org.il> >>.

=head1 SEE ALSO

L<Test::Run>

=cut

sub _def_or_blank {
    return $_[0] if defined $_[0];
    return "";
}

1;
