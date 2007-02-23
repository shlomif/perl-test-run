# -*- Mode: cperl; cperl-indent-level: 4 -*-

package Test::Run::Core;

require 5.00405;
use Test::Run::Straps;
use Test::Run::Output;
use Test::Run::Base;
use Test::Run::Assert;
use Test::Run::Obj::Structs;
use Test::Run::Obj::Error;
use Exporter;
use Benchmark;
use Config;
use strict;

use Class::Accessor;

use Scalar::Util ();

use vars qw(
    $VERSION
    @ISA
);

use vars qw($has_time_hires);
BEGIN {
    eval "use Time::HiRes 'time'";
    $has_time_hires = !$@;
}

=head1 NAME

Test::Run::Core - Run Perl standard test scripts with statistics

=head1 VERSION

Version 0.0104

=cut

$VERSION = '0.0104';

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_NG_VERSION} = $VERSION;

END {
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_NG_VERSION};
}

@ISA = ('Test::Run::Base', 'Exporter');

__PACKAGE__->mk_accessors(qw(
    _bonusmsg
    Columns
    Debug
    Leaked_Dir
    NoTty
    Strap
    Switches
    Switches_Env
    Test_Interpreter
    Timer
    Verbose
    dir_files
    failed_tests
    format_columns
    list_len
    max_namelen
    output
    test_files
    tot
    width
));


sub _get_simple_params
{
    return
        [qw(
            Columns
            Debug
            Leaked_Dir
            NoTty
            Switches
            Switches_Env
            Verbose
            Test_Interpreter
            Timer
            test_files
       )];
}

sub _init_simple_params
{
    my ($self, $args) = @_;
    foreach my $key (@{$self->_get_simple_params()})
    {
        if (exists($args->{$key}))
        {
            $self->set($key, $args->{$key});
        }
    }
}


sub _get_new_strap
{
    my $self = shift;

    return Test::Run::Straps->new(+{})
}

sub _initialize
{
    my ($self, $args) = @_;

    $self->Columns(80);
    $self->Switches("-w");
    $self->_init_simple_params($args);
    $self->dir_files([]);
    $self->Strap(
        $self->_get_new_strap($args),
    );
    return 0;
}

=head1 SYNOPSIS

  use Test::Run::Obj;

  my $tester = Test::Run::Obj->new({'test_files' => \@test_files});
  $tester->runtests();

=head1 DESCRIPTION

B<STOP!> If all you want to do is write a test script, consider
using Test::Simple.  Test::Run::Core is the module that reads the
output from Test::Simple, Test::More and other modules based on
Test::Builder.  You don't need to know about Test::Run::Core to use
those modules.

Test::Run::Core runs tests and expects output from the test in a
certain format.  That format is called TAP, the Test Anything
Protocol.  It is defined in L<Test::Harness::TAP>.

C<$tester->runtests()> runs all the testscripts named
as arguments and checks standard output for the expected strings
in TAP format.

L<Test::Run::Obj> is an applicative derived class of Test::Run::Core
that provides a programmer API for running and analyzing the output of TAP 
files. For calling from the command line, look at
L<Test::Run::CmdLine>.

=head2 Taint mode

Test::Run will honor the C<-T> or C<-t> in the #! line on your
test files.  So if you begin a test with:

    #!perl -T

the test will be run with taint mode on.

=head2 Object Parameters

These parameters are accessors. They can be set at object creation by passing
their name along with a value on the constructor (along with the compulsory
C<'test_files'> argument):

    my $tester = Test::Run::Obj->new(
        {
            'test_files' => \@mytests,
            'Verbose' => 1,
        }
    );

Alternatively, before C<runtests()> is called, they can be set by passing a 
value to their accessor:

    $tester->Verbose(1);

=over 4

=item C<$self-E<gt>Verbose()>

The object variable C<$self-E<gt>Verbose()> can be used to let C<runtests()> 
display the standard output of the script without altering the behavior
otherwise.  The F<runprove> utility's C<-v> flag will set this.

=item C<$self-E<gt>Leaked_Dir()>

When set to the name of a directory, C<$tester> will check after each
test whether new files appeared in that directory, and report them as

  LEAKED FILES: scr.tmp 0 my.db

If relative, directory name is with respect to the current directory at
the moment C<$tester-E<gt>runtests()> was called.  Putting the absolute path 
into C<Leaked_Dir> will give more predictable results.

=item C<$self-E<gt>Debug()> 

If C<$self-E<gt>Debug()> is true, Test::Run will print debugging information
about itself as it runs the tests.  This is different from
C<$self-E<gt>Verbose()>, which prints the output from the test being run.

=item C<$self-E<gt>Columns()>

This value will be used for the width of the terminal. If it is not
set then it will default to 80.

=item C<$self-E<gt>Timer()>

If set to true, and C<Time::HiRes> is available, print elapsed seconds
after each test file.

=item C<$self-E<gt>NoTty()>

When set to a true value, forces it to behave as though STDOUT were
not a console.  You may need to set this if you don't want harness to
output more frequent progress messages using carriage returns.  Some
consoles may not handle carriage returns properly (which results in a
somewhat messy output).

=item C<$self-E<gt>Test_Interprter()>

Usually your tests will be run by C<$^X>, the currently-executing Perl.
However, you may want to have it run by a different executable, such as
a threading perl, or a different version.

=item C<$self-E<gt>Switches()> and C<$self-E<gt>Switches_Env()>

These two values will be prepended to the switches used to invoke perl on
each test.  For example, setting one of them to C<-W> will
run all tests with all warnings enabled.

The difference between them is that C<Switches_Env()> is expected to be 
filled in by the environment and C<Switches()> from other sources (like the
programmer).

=back

=head2 Failure

When tests fail, analyze the summary report:

  t/base..............ok
  t/nonumbers.........ok
  t/ok................ok
  t/test-harness......ok
  t/waterloo..........dubious
          Test returned status 3 (wstat 768, 0x300)
  DIED. FAILED tests 1, 3, 5, 7, 9, 11, 13, 15, 17, 19
          Failed 10/20 tests, 50.00% okay
  Failed Test  Stat Wstat Total Fail  Failed  List of Failed
  -----------------------------------------------------------------------
  t/waterloo.t    3   768    20   10  50.00%  1 3 5 7 9 11 13 15 17 19
  Failed 1/5 test scripts, 80.00% okay. 10/44 subtests failed, 77.27% okay.

Everything passed but F<t/waterloo.t>.  It failed 10 of 20 tests and
exited with non-zero status indicating something dubious happened.

The columns in the summary report mean:

=over 4

=item B<Failed Test>

The test file which failed.

=item B<Stat>

If the test exited with non-zero, this is its exit status.

=item B<Wstat>

The wait status of the test.

=item B<Total>

Total number of tests expected to run.

=item B<Fail>

Number which failed, either from "not ok" or because they never ran.

=item B<Failed>

Percentage of the total tests which failed.

=item B<List of Failed>

A list of the tests which failed.  Successive failures may be
abbreviated (ie. 15-20 to indicate that tests 15, 16, 17, 18, 19 and
20 failed).

=back


=head2 Functions

Test::Run currently only has one interface function, here it is.

=over 4

=item B<runtests>

  my $allok = $self->runtests();

This runs all the given I<@test_files> and divines whether they passed
or failed based on their output to STDOUT (details above).  It prints
out each individual test which failed along with a summary report and
a how long it all took.

It returns true if everything was ok.  Otherwise it will C<die()> with
one of the messages in the DIAGNOSTICS section.

=cut

sub _real_runtests
{
    my $self = shift;
    my($failedtests) =
        $self->_run_all_tests();

    $self->_show_results();

    my $ok = $self->_all_ok();

    assert(($ok xor keys %$failedtests), 
           q{ok status jives with $failedtests});

    return $ok;
}

sub _is_error_object
{
    my $self = shift;
    my $error = shift;

    return
    (
        Scalar::Util::blessed($error) &&
        $error->isa("Test::Run::Obj::Error::TestsFail")
    );
}

sub _handle_runtests_error_text
{
    my $self = shift;
    my $args = shift;

    my $text = $args->{'text'};

    die $text;
}

sub _get_runtests_error_text
{
    my $self = shift;
    my $error = shift;
    
    return 
        ($self->_is_error_object($error)
            ? $error->stringify()
            : $error
        );
}

sub _handle_runtests_error
{
    my $self = shift;
    my $args = shift;
    my $error = $args->{'error'};

    $self->_handle_runtests_error_text(
        {
            'text' => $self->_get_runtests_error_text($error),
        },
    );
}

sub runtests
{
    my $self = shift;

    local ($\, $,);

    my $ok = eval { $self->_real_runtests(@_) };
    if ($@)
    {
        return $self->_handle_runtests_error(
            {
                'ok' => $ok, 
                'error' => $@,
            }
        );
    }
    else
    {
        return $ok;
    }
}

=begin _private

=item B<_all_ok>

  my $ok = $self->_all_ok();

Tells you if this test run is overall successful or not.

=cut

sub _all_ok {
    my $self = shift;
    my $tot = $self->tot();

    return (
        (
            ($tot->bad() == 0) &&
            ($tot->max() || $tot->skipped())
        ) ? 1 : 0
    );
}

=item B<_globdir>

  my @files = _globdir $dir;

Returns all the files in a directory.  This is shorthand for backwards
compatibility on systems where C<glob()> doesn't work right.

=cut

sub _globdir {
    opendir DIRH, shift; 
    my @f = readdir DIRH; 
    closedir DIRH; 

    return @f;
}

=item B<_run_all_tests>

  my($total, $failed) = _run_all_tests();

Runs all the test_files defined for the object but does it
quietly (no report).  $total is a hash ref summary of all the tests
run.  Its keys and values are this:

    bonus           Number of individual todo tests unexpectedly passed
    max             Number of individual tests ran
    ok              Number of individual tests passed
    sub_skipped     Number of individual tests skipped
    todo            Number of individual todo tests

    files           Number of test files ran
    good            Number of test files passed
    bad             Number of test files failed
    tests           Number of test files originally given
    skipped         Number of test files skipped

If C<< $total->{bad} == 0 >> and C<< $total->{max} > 0 >>, you've
got a successful test.

$failed is a hash ref of all the test scripts which failed.  Each key
is the name of a test script, each value is another hash representing
how that script failed.  Its keys are these:

    name        Name of the test which failed
    estat       Script's exit value
    wstat       Script's wait status
    max         Number of individual tests
    failed      Number which failed
    percent     Percentage of tests which failed
    canon       List of tests which failed (as string).

C<$failed> should be empty if everything passed.

B<NOTE> Currently this function is still noisy.  I'm working on it.

=cut

# Turns on autoflush for the handle passed
sub _autoflush {
    my $flushy_fh = shift;
    my $old_fh = select $flushy_fh;
    $| = 1;
    select $old_fh;
}

sub _get_dir_files
{
    my $self = shift;
    return [ _globdir($self->Leaked_Dir()) ];
}

sub _init_dir_files
{
    my $self = shift;
    my @dir_files;
    if (defined($self->Leaked_Dir()))
    {
        $self->dir_files($self->_get_dir_files());    
    }  
}

=head2 $self->_report_leaked_files({leaked_files => [@files]})

[This is a method that needs to be over-rided.]

Should report (or ignore) the files that were leaked in the directories
that were specifies as leaking directories.

=cut

sub _recheck_dir_files
{
    my $self = shift;
    
    if (defined $self->Leaked_Dir()) {
        my $new_dir_files = $self->_get_dir_files();
        if (@$new_dir_files != @{$self->dir_files()}) {
            my %f;
            @f{@$new_dir_files} = (1) x @$new_dir_files;
            delete @f{@{$self->dir_files()}};
            $self->_report_leaked_files({'leaked_files' => [sort keys %f]});
            $self->dir_files($new_dir_files);
        }
    }
}

sub _tot_add
{
    my ($self, $field, $diff) = @_;
    $self->tot()->add($field, $diff);
}

sub _tot_inc
{
    my ($self, $field) = @_;
    $self->_tot_add($field,1);
}

sub _create_failed_obj_instance
{
    my $self = shift;
    my $args = shift;
    return Test::Run::Obj::FailedObj->new(
        $args
    );
}

sub _is_failed_and_max
{
    my ($self, $args) = @_;
    my $test = $args->{'test_struct'};

    return (@{$test->failed()} and $test->max());
}

sub _get_failed_and_max_msg
{
    my ($self, $args) = @_;
    my $test = $args->{'test_struct'};

    my ($txt) = $self->_canonfailed($test);

    return ($test->ml().$txt);
}

sub _get_dont_know_which_tests_failed_msg
{
    my ($self, $args) = @_;
    my $test = $args->{'test_struct'};
    
    return
        ("Don't know which tests failed: got " . $test->ok() . " ok, ".
              "expected " . $test->max()
        );
}

sub _get_failed_with_results_seen_msg
{
    my ($self, $args) = @_;
    my $test = $args->{'test_struct'};
    
    return 
        $self->_is_failed_and_max($args)
            ? $self->_get_failed_and_max_msg($args)
            : $self->_get_dont_know_which_tests_failed_msg($args)
            ;
}

=head2 $self->_report_failed_with_results_seen({%args})

[This is a method that needs to be over-rided.]

Should report (or ignore) the failed tests in the test file.

Arguments are:

=over 4

=item * test_struct 

The test struct as returned by straps.

=item * filename

The filename

=item * estatus

Exit status.

=item * wstatus

Wait status.

=item * results

The results of the test.

=back

=cut

sub _get_failed_and_max_params
{
    my ($self, $args) = @_;
    
    my $test = $args->{'test_struct'};

    my (undef, $canon) = $self->_canonfailed($test);

    return 
        [
            canon   => $canon,
            failed  => scalar @{$test->failed()},
            percent => 100*(scalar @{$test->failed()})/$test->max(),
        ];
}

sub _get_undef_tests_params
{
    return 
        [
            canon   => '??',
            failed  => '??',
            percent => undef,
        ];
}

# FWRS == failed_with_results_seen

sub get_common_FWRS_params
{
    my ($self, $args) = @_;

    my $test = $args->{'test_struct'};

    return
        [
            max     => $test->max(),
            name    => $args->{'filename'},
            estat   => '',
            wstat   => '',
        ];
}

sub _get_FWRS_tests_existence_params
{
    my ($self, $args) = @_;

    return
        [
            $self->_is_failed_and_max($args)
            ? (@{$self->_get_failed_and_max_params($args)})
            : (@{$self->_get_undef_tests_params($args)})
        ]
}

sub _get_failed_with_results_seen_params
{
    my ($self, $args) = @_;

    return 
        {
            @{$self->get_common_FWRS_params($args)},
            @{$self->_get_FWRS_tests_existence_params($args)},
        }
}

sub _failed_with_results_seen
{
    my ($self, $args) = @_;

    $self->_tot_inc('bad');

    $self->_report_failed_with_results_seen($args);

    return
        $self->_create_failed_obj_instance(
            $self->_get_failed_with_results_seen_params($args)
        );
}

=head2 $self->_report_failed_before_any_test_output();

[This is a method that needs to be over-rided.]

=cut

sub _failed_before_any_test_output
{
    my ($self, $args) = @_;

    my $tfile = $args->{'filename'};

    $self->_report_failed_before_any_test_output();

    $self->_tot_inc('bad');

    return $self->_create_failed_obj_instance(
        {
            canon       => '??',
            max         => '??',
            failed      => '??',
            name        => $tfile,
            percent     => undef,
            estat       => '', 
            wstat       => '',
        }
        );
}

sub _get_failed_struct
{
    my ($self, $args) = @_;
    if ($args->{'wstatus'}) {
         return
            $self->_dubious_return(
                $args
                );
    }
    elsif($args->{'results'}->seen()) {
        return
            $self->_failed_with_results_seen(
                $args,
            );
    }
    else {
        return
            $self->_failed_before_any_test_output(
                $args,
            );
    }
}

sub _list_tests_as_failures
{
    my $self = shift;
    my $args = shift;

    my $test = $args->{test_struct};
    my $results = $args->{results};

    # List unrun tests as failures.
    if ($test->next() <= $test->max()) {
        $test->add_to_failed($test->next()..$test->max());
    }
    # List overruns as failures.
    else {
        my $details = $results->details();
        foreach my $overrun ($test->max()+1..@$details) {
            next unless ref $details->[$overrun-1];
            $test->add_to_failed($overrun);
        }
    }
}

sub _tot_add_results
{
    my $self = shift;
    my $results = shift;

    foreach my $type (qw(bonus max ok todo))
    {
        $self->_tot_add($type => $results->get($type));
    }
    $self->_tot_add(sub_skipped => $results->skip());
}

sub _get_elapsed
{
    my ($self, $args) = @_;

    if ( $self->Timer() ) {
        my $elapsed = time - $args->{start_time};
        if ( $has_time_hires ) {
            return sprintf( " %8.3fs", $elapsed );
        }
        else {
            return sprintf( " %8ss", $elapsed ? $elapsed : "<1" );
        }
    }
    else {
        return "";
    }
}

sub _get_copied_strap_fields
{
    return [qw(Debug Test_Interpreter Switches Switches_Env)];
}

sub _init_strap
{
    my ($self, $tfile) = @_;

    $self->Strap()->copy_from($self, $self->_get_copied_strap_fields());
}

sub _time_single_test
{
    my $self = shift;
    my $tfile = shift;

    my $test_start_time = $self->Timer() ? time : 0;

    $self->_init_strap($tfile);
    $self->Strap()->callback(sub { $self->_strap_callback(@_); });
    # We trap exceptions so we can nullify the callback to avoid memory
    # leaks.
    my $results;
    eval {
        $results = $self->Strap()->analyze_file($tfile) or
          do { warn $self->Strap()->error(), "\n";  next };
    };
    $self->Strap()->callback(undef);
    if ($@ ne "")
    {
        die $@;
    }
    
    my $elapsed = $self->_get_elapsed({'start_time' => $test_start_time});
    return ($results, $elapsed);
}

=head2 $self->_report_skipped_test({test_struct => $test, elapsed => $elapsed})

[This is a method that needs to be over-rided.]

Should report the skipped test.

=cut

sub _process_skipped_test
{
    my ($self, $args) = @_;

    return $self->_report_skipped_test($args);
}

=head2 $self->_report_all_ok_test({test_struct => $test, elapsed => $elapsed})

[This is a method that needs to be over-rided.]

Should report the all OK test.

=cut

sub _process_all_ok_test
{
    my ($self, $args) = @_;
    return $self->_report_all_ok_test($args);
}

=head2 $self->_report_all_skipped_test({test_struct => $test, elapsed => $elapsed})

[This is a method that needs to be over-rided.]

Should report the all-skipped test.

=cut

sub _process_all_skipped_test
{
    my ($self, $args) = @_;

    $self->_report_all_skipped_test($args);
    $self->_tot_inc('skipped');
}

sub _process_passing_test
{
    my ($self, $args) = @_;

    my $test = $args->{test_struct};
    my $elapsed = $args->{elapsed};

    # XXX Combine these first two
    if ($test->max() and $test->skipped() + $test->bonus())
    {
        $self->_process_skipped_test($args);
    }
    elsif ( $test->max() )
    {
        $self->_process_all_ok_test($args);        
    }
    else
    {
        $self->_process_all_skipped_test($args);
    }
    $self->_tot_inc('good');
}

sub _create_test_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Obj::TestObj->new($args);
}

=head2 $self->_calc_test_struct_ml($results)

Calculates the ml(). (See L<Test::Run::Output>) for the test. 

=cut

sub _calc_test_struct_ml
{
    return "";
}

sub _get_test_struct
{
    my $self = shift;
    my $results = shift;

    $self->_tot_add_results($results);

    return 
        $self->_create_test_obj_instance(
            {
                ok          => $results->ok(),
                'next'      => $self->Strap()->next(),
                max         => $results->max(),
                # state of the current test.
                failed      => [
                    grep { !$results->details()->[$_-1]{ok} }
                     (1 .. @{$results->details()})
                               ],
                bonus       => $results->bonus(),
                skipped     => $results->skip(),
                skip_reason => $results->skip_reason(),
                skip_all    => $results->skip_all(),
                ml          => $self->_calc_test_struct_ml($results),
            }
        );
}

=head2 $self->_report_single_test_file_start({test_file => "t/my_test_file.t"})

[This is a method that needs to be over-rided.]

Should start the report for the C<test_file> file.

=cut


sub _prepare_for_single_test_run
{
    my ($self, $args) = @_;

    $self->_tot_inc('files');
    $self->Strap()->_seen_header(0);

    $self->_report_single_test_file_start($args);

    return;
}

sub _run_single_test
{
    my ($self, $args) = @_;

    my $tfile = $args->{'test_file'};

    $self->_prepare_for_single_test_run($args);

    my ($results, $elapsed) = $self->_time_single_test($tfile);

    my $test = $self->_get_test_struct($results);

    my($estatus, $wstatus) = @{$results}{qw(exit wait)};

    if ($results->{passing}) 
    {
        $self->_process_passing_test(
            {
                test_struct => $test,
                elapsed => $elapsed,
            },
        );
    }
    else {
        $self->_list_tests_as_failures(
            {
                'test_struct' => $test,
                'results' => $results,
            }
        ); 
        $self->failed_tests()->{$tfile} = 
            $self->_get_failed_struct(
                {
                    test_struct => $test,
                    estatus => $estatus,
                    wstatus => $wstatus,
                    filename => $tfile,
                    results => $results,
                }
            );
    }

    $self->_recheck_dir_files();
}

sub _get_tot_counter_tests
{
    my $self = shift;
    return [tests => (scalar @{$self->test_files()})];
}

sub _init_tot_obj_instance
{
    my $self = shift;
    return Test::Run::Obj::TotObj->new(
        { @{$self->_get_tot_counter_tests()} },
    );
}

sub _init_tot
{
    my $self = shift;
    $self->tot(
        $self->_init_tot_obj_instance()
    );
}

sub _run_all_tests {
    my $self = shift;

    _autoflush(\*STDOUT);
    _autoflush(\*STDERR);

    $self->failed_tests({});

    $self->_init_tot();

    $self->_init_dir_files();
    my $run_start_time = new Benchmark;

    $self->width($self->_leader_width());
    foreach my $tfile (@{$self->test_files()}) 
    {
        $self->_run_single_test({'test_file' => $tfile});
    } # foreach test
    $self->tot()->bench(timediff(new Benchmark, $run_start_time));

    $self->Strap()->_restore_PERL5LIB;

    # TODO: Eliminate this? -- Shlomi Fish
    return $self->failed_tests();
}


=item B<_leader_width>

  my($width) = $self->_leader_width();

Calculates how wide the leader should be based on the length of the
longest test name.

=cut

sub _leader_width {
    my ($self) = @_;
    my $tests = $self->test_files();

    my $maxlen = 
        $self->__max_num_flat(map {length($_)} @$tests);
    my $maxsuflen =
        $self->__max_num_flat(map {length(/\.(\w+)$/ ? $1 : '')} @$tests);

    # + 3 : we want three dots between the test name and the "ok"
    return $maxlen + 3 - $maxsuflen;
}

=head2 $self->_report('channel' => $channel, 'event' => $event_handle);

[This is a method that needs to be over-rided.]

Reports the C<$event_handle> event to channel C<$channel>. This should be 
overrided by derived classes to do alternate functionality besides calling 
output()->print_message(), also different based on the channel.

Currently available channels are:

=over 4

=item 'success'

The success report.

=back

An event is a hash ref that should contain a 'type' property. Currently 
supported types are:

=over 4

=item * success

A success type.

=back

=cut

sub _get_success_msg
{
    my $self = shift;
    return "All tests successful" . $self->_get_bonusmsg() . ".";
}

sub _report_success
{
    my $self = shift;
    $self->_report(
        {
            'channel' => "success",
            'event' => { 'type' => "success", },
        }
    );
}

sub _get_fail_no_tests_run_text
{
    return "FAILED--no tests were run for some reason.\n"
}

sub _fail_no_tests_run
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoTestsRun->new(
        {text => $self->_get_fail_no_tests_run_text(),},
    );
}

sub _get_fail_no_tests_output_text
{
    my $self = shift;
    my $num_tests = $self->tot()->tests();
    my $blurb = "script" . $self->_get_s($num_tests);
    
    return "FAILED--$num_tests test $blurb could be run, ".
        "alas--no output ever seen\n";
}

sub _fail_no_tests_output
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoOutput->new(
        {text => $self->_get_fail_no_tests_output_text(),},
    );
}

=head2 $self->_report_final_stats()

[This is a method that needs to be over-rided.]

Reports the final statistics.

=cut

sub _get_tests_good_percent
{
    my ($self) = @_;
    return sprintf("%.2f", $self->tot()->good() / $self->tot()->tests() * 100);
}

sub _get_sub_percent_msg
{
    my $self = shift;
    my $tot = $self->tot();
    my $percent_ok = 100*$tot->ok()/$tot->max();
    return sprintf(" %d/%d subtests failed, %.2f%% okay.",
        $tot->max() - $tot->ok(), $tot->max(), 
        $percent_ok
        );
}

sub _get_format_failed_str
{
    return "Failed Test";
}

sub _get_format_middle_str
{
    return " Stat Wstat Total Fail  Failed  ";
}

sub _get_format_list_str
{
    return "List of Failed";
}

sub _get_format_failed_str_len
{
    my $self = shift;
    return length($self->_get_format_failed_str());
}

sub __max_num_flat
{
    my $self = shift;
    my $n = shift;
    return $self->__max_num($n, [@_]);
}

sub __max_num
{
    my ($self, $max, $others )= @_;
    foreach my $n (@$others)
    {
        $max = $n if $n > $max;
    }
    return $max;
}

sub _get_format_tests_namelens
{
    my $self = shift;
    return [map { length($_->{name}) } values(%{$self->failed_tests()})];
}

sub _get_initial_max_namelen
{
    my $self = shift;
    # Figure out our longest name string for formatting purposes.
    return 
        $self->__max_num(
            $self->_get_format_failed_str_len(),
            $self->_get_format_tests_namelens(),
        );
}

sub _get_fmt_mid_str_len
{
    my $self = shift;
    return length($self->_get_format_middle_str());
}

sub _get_fmt_list_str_len
{
    my $self = shift;
    return length($self->_get_format_list_str());
}

sub _get_num_columns
{
    my $self = shift;
    # Some shells have trouble with a full line of text.
    return ($self->Columns()-1);
}

sub _get_fmt_list_len
{
    my ($self, $args) = (@_);

    my $max_nl_ref = $args->{max_namelen};

    $self->format_columns($self->_get_num_columns());

    my $list_len = $self->format_columns() - $self->_get_fmt_mid_str_len() - $$max_nl_ref;
    if ($list_len < $self->_get_fmt_list_str_len()) {
        $list_len = $self->_get_fmt_list_str_len();
        $$max_nl_ref = $self->format_columns() - $self->_get_fmt_mid_str_len() - $list_len;
        if ($$max_nl_ref < $self->_get_format_failed_str_len()) {
            $$max_nl_ref = $self->_get_format_failed_str_len();
            $self->format_columns(
                $$max_nl_ref + $self->_get_fmt_mid_str_len() + $list_len
            );
        }
    }
    return $list_len;
}

sub _calc_format_widths
{
    my $self = shift;

    my $max_namelen = $self->_get_initial_max_namelen();

    my $list_len = $self->_get_fmt_list_len({'max_namelen' => \$max_namelen});

    $self->max_namelen($max_namelen);
    $self->list_len($list_len);

    return 0;
}

=head2 $self->_fail_other_print_top()

[This is a method that needs to be over-rided.]

Prints the header of the files that failed.

=cut

sub _fail_other_get_canon_strings
{
    my $self = shift;
    my $canon = shift;
    my @ret = ();
    my $string = shift(@$canon);
    while (@$canon)
    {
        if (length($canon->[0]) + 1 + length($string)< $self->list_len())
        {
            $string .= " ".shift(@$canon);
        }
        else
        {
            push @ret, $string;
            $string = shift(@$canon);
        }
    }
    push @ret, $string;
    return \@ret;
}

=head2 $self->_fail_other_report_test($script_name)

[This is a method that needs to be over-rided.]

In case of failure from a different reason - report that test script.
Test::Run iterates over all the scripts and reports them one by one.

=cut

sub _create_fmts 
{
    my $self = shift;
    my $failedtests = $self->failed_tests();

    $self->_calc_format_widths();

    return 0;
}

sub _get_fail_test_scripts_string
{
    my $self = shift;
    return $self->tot()->bad() . "/" .
        $self->tot()->tests(). " test scripts";
}

sub _get_fail_tests_good_percent_string
{
    my $self = shift;
    return ", " .
        $self->_get_tests_good_percent() . "% okay";
}

sub _get_fail_other_exception_text
{
    my $self = shift;
    return "Failed " . 
        $self->_get_fail_test_scripts_string() . 
        $self->_get_fail_tests_good_percent_string() .
        "." .
        $self->_get_sub_percent_msg() . 
        "\n";
}

sub _fail_other_throw_exception
{
    my $self = shift;

    die Test::Run::Obj::Error::TestsFail::Other->new(
        {text => $self->_get_fail_other_exception_text(),},
    );
}

sub _fail_other_get_script_names
{
    my $self = shift;
    return [ sort keys %{$self->failed_tests()} ]
}

sub _fail_other_print_all_tests
{
    my $self = shift;
    # Now write to formats
    for my $script (@{$self->_fail_other_get_script_names()})
    {
         $self->_fail_other_report_test($script);
    }
}

=head2 $self->_fail_other_print_bonus_message()

[This is a method that needs to be over-rided.]

Should report the bonus message in case of failure from a different
reason.

=cut

sub _fail_other
{
    my $self = shift;

    $self->_create_fmts();

    $self->_fail_other_print_top();

    $self->_fail_other_print_all_tests();

    if ($self->tot()->bad())
    {
        $self->_fail_other_print_bonus_message();
        $self->_fail_other_throw_exception();
    }
}

sub _show_results {
    my($self) = @_;
    my $tot = $self->tot();

    if ($self->_all_ok())
    {
        $self->_report_success();
    }
    elsif (!$tot->tests())
    {
        $self->_fail_no_tests_run();
    }
    elsif (!$tot->max())
    {
        $self->_fail_no_tests_output();
    }
    else
    {
        $self->_fail_other();
    }
    $self->_report_final_stats();
}

=head2 $self->_report_tap_event({ 'raw_event' => $event->raw() })

[This is a method that needs to be over-rided.]

=head2 $self->_report_script_start_environment()

[This is a method that needs to be over-rided.]

Should report the environment of the script at its beginning.

=head2 $self->_handle_test_file_opening_error($args)

[This is a method that needs to be over-rided.]

Should handle the case where the test file cannot be opened.

=cut

sub _strap_callback
{
    my ($self, $args) = @_;
    
    my $type = $args->{type};

    if ($type eq "tap_event")
    {
        return $self->_tap_event_strap_callback($args);
    }
    elsif ($type eq "report_start_env")
    {
        return $self->_report_script_start_environment($args);
    }
    elsif ($type eq "could_not_run_script")
    {
        return $self->_report_could_not_run_script($args);
    }
    elsif ($type eq "test_file_opening_error")
    {
        return $self->_handle_test_file_opening_error($args);
    }
    elsif ($type eq "test_file_closing_error")
    {
        return $self->_handle_test_file_closing_error($args);
    }
}

sub _tap_event_strap_callback
{
    my $self = shift;
    my ($args) = @_;

    my $event = $args->{event};
    my $totals = $args->{totals};

    $self->_report_tap_event({ 'raw_event' => $event->raw()});

    if ($event->is_plan())
    {
        return $self->_strap_header_handler(@_);
    }
    elsif ($event->is_bailout())
    {
        return $self->_strap_bailout_handler(@_);
    }
    elsif ($event->is_test())
    {
        return $self->_strap_test_handler(@_);
    }
    else
    {
        return;
    }
};


sub _strap_header_handler {
    my($self, $args) = @_;

    my $totals = $args->{totals};

    if ($self->Strap->_seen_header())
    {
        warn "Test header seen more than once!\n";
    }

    $self->Strap->_inc_seen_header();

    if ($totals->seen() && 
        ($totals->max()  < $totals->seen())
       )
    {
        warn "1..M can only appear at the beginning or end of tests\n";
    }

    return;
};

=head2 $self->_report_test_progress($args)

[This is a method that needs to be over-rided.]

Report the text progress. In the command line it would be a ok $curr/$total
or NOK.

=cut

sub _strap_test_handler
{
    my ($self, $args) = @_;

    my $totals = $args->{totals};

    my $detail = $totals->last_detail;

    if ( $detail->ok() )
    {
        $totals->update_skip_reason($detail);
    }

    $self->_report_test_progress($args);
    return;
}

sub _strap_bailout_handler
{
    my ($self, $args) = @_;

    die Test::Run::Obj::Error::TestsFail::Bailout->new(
        {
            bailout_reason => $self->Strap->bailout_reason(),
            text => "FOOBAR",
        }
    );
};

sub _get_s
{
    my ($self, $n) = @_;
    return ($n != 1 ? 's' : '')
}

sub _get_skipped_bonusmsg
{
    my $self = shift;
    my $tot = $self->tot();
    my $sub_skipped = $tot->sub_skipped();
    my $skipped = $tot->skipped();

    # TODO: Refactor it.
    my $sub_skipped_msg =
        "$sub_skipped subtest" . $self->_get_s($sub_skipped);

    my $comma = ", ";
    if ($skipped)
    {
        return 
            $comma . "$skipped test" .
            $self->_get_s($skipped) .
            ($sub_skipped ? (" and " . $sub_skipped_msg) : "") .
            ' skipped'
            ;
    }
    elsif ($sub_skipped)
    {
        # Should be a comma here too.
        return $comma . "$sub_skipped_msg skipped";
    }
    else
    {
        return "";
    }
}

sub _get_bonusmsg {
    my($self) = @_;
    my $bonus = $self->tot()->bonus();

    if (defined($self->_bonusmsg()))
    {
        return $self->_bonusmsg();
    }

    my $bonusmsg = '';
    $bonusmsg = (" ($bonus subtest".($bonus > 1 ? 's' : '').
               " UNEXPECTEDLY SUCCEEDED)")
        if $bonus;

    $bonusmsg .= $self->_get_skipped_bonusmsg();

    $self->_bonusmsg($bonusmsg);

    return $bonusmsg;
}

=head2 The common test-context $args param

Contains:

=over 4

=item 'test_struct' => $test

A reference to the test summary object.

=item estatus

The exit status of the test file.

=back

=head2 $test_run->_report_dubious($args)

[This is a method that needs to be over-rided.]

Is called to report the "dubious" error, when the test returns a non-true
error code.

$args are the test-context - see above.

=cut

=head2 $test_run->_report_dubious_summary_all_subtests_successful($args)

[This is a method that needs to be over-rided.]

$args are the test-context - see above.

=head2 $test_run->_report_premature_test_dubious_summary($args)

[This is a method that needs to be over-rided.]

$args are the test-context - see above.

=cut

sub _get_premature_test_dubious_summary
{
    my ($self, $args) = @_;

    my $test = $args->{'test_struct'};

    $test->add_to_failed($test->next()..$test->max());

    my (undef, $canon) = $self->_canonfailed($test);

    $self->_report_premature_test_dubious_summary($args);

    return 
    {
        failed => scalar(@{$test->failed()}),
        canon => $canon,
        percent => (100*(scalar @{$test->failed()})/$test->max()),
    };
}

sub _get_dubious_summary
{
    my ($self, $args) = @_;

    my $test = $args->{'test_struct'};

    if ($test->max())
    {
        if ($test->next() == $test->max() + 1 and not @{$test->failed()})
        {
            $self->_report_dubious_summary_all_subtests_successful($args);
            
            return
            {
                failed => 0,
                percent => 0,
                canon => "??",
            };
        }
        else
        {
            return
                $self->_get_premature_test_dubious_summary($args);
        }
    }
    else
    {
        return
        {
            failed => "??",
            canon => "??",
            percent => undef,
        };
    }

}

# Test program go boom.
sub _dubious_return 
{
    my ($self, $args) = @_;
    
    my $test = $args->{'test_struct'};
    my $estatus = $args->{'estatus'};
    my $wstatus = $args->{'wstatus'};
    my $filename = $args->{'filename'};
    
    $self->_report_dubious($args);

    $self->_tot_inc('bad');

    my $dubious_summary = $self->_get_dubious_summary($args);

    return 
        $self->_create_failed_obj_instance(
            {
                %{$dubious_summary},
                max => $test->max() || '??',
                estat => $estatus,
                wstat => $wstatus,
                name => $filename,
            }
        );
}

sub filter_failed
{
    my ($self, $failed_ref) = @_;
    my %seen;
    return [ sort {$a <=> $b} grep !$seen{$_}++, @$failed_ref ];
}

sub _get_failed_string
{
    my ($self, $canon) = @_;
    return
        ("FAILED test" . ((@$canon > 1) ? "s" : "") .
         " " . join(", ", @$canon) . "\n"
        );
}

sub _canonfailed_get_canon_ranges
{
    my ($self, $failed) = @_;
    my $min = shift @$failed;
    my $last = $min;
    my @canon;
    for my $test (@$failed, $failed->[-1]) # don't forget the last one
    {
        if ($test > $last+1 || $test == $last) {
            push @canon, ($min == $last) ? $last : "$min-$last";
            $min = $test;
        }
        $last = $test;
    }
    return \@canon;
}

sub _canonfailed_get_canon_helper
{
    my ($self, $failed) = @_;
    if (@$failed == 1)
    {
        return [ @$failed ];
    }
    else
    {
        return $self->_canonfailed_get_canon_ranges($failed);
    }
}

sub _canonfailed_get_canon
{
    my ($self, $args) = @_;

    my $failed_in = $args->{failed_in};

    my $failed = $self->filter_failed($failed_in);
    my $failed_num = @$failed;

    my $canon = $self->_canonfailed_get_canon_helper($failed);
    return Test::Run::Obj::CanonFailedObj->new(
        {
            canon => join(' ', @$canon),
            result => [$self->_get_failed_string($canon)],
            failed_num => $failed_num,
        },
    );
}

sub _canonfailed {
    my ($self, $test) = @_;

    my $canon_obj =
        $self->_canonfailed_get_canon(
            {
                'failed_in' => $test->failed(),
            },
        );

    $canon_obj->add_Failed($test);
    $canon_obj->add_skipped($test);

    return ($canon_obj->get_ser_results(), $canon_obj->canon());
}

=end _private

=back

=cut


1;
__END__


=head1 EXPORT

None.

=head1 DIAGNOSTICS

=over 4

=item C<All tests successful.\nFiles=%d,  Tests=%d, %s>

If all tests are successful some statistics about the performance are
printed.

=item C<FAILED tests %s\n\tFailed %d/%d tests, %.2f%% okay.>

For any single script that has failing subtests statistics like the
above are printed.

=item C<Test returned status %d (wstat %d)>

Scripts that return a non-zero exit status, both C<$? E<gt>E<gt> 8>
and C<$?> are printed in a message similar to the above.

=item C<Failed 1 test, %.2f%% okay. %s>

=item C<Failed %d/%d tests, %.2f%% okay. %s>

If not all tests were successful, the script dies with one of the
above messages.

=item C<FAILED--Further testing stopped: %s>

If a single subtest decides that further testing will not make sense,
the script dies with this message.

=back

=head1 ENVIRONMENT VARIABLES THAT TEST::HARNESS SETS

Test::Run sets these before executing the individual tests.

=over 4

=item C<HARNESS_ACTIVE>

This is set to a true value.  It allows the tests to determine if they
are being executed through the harness or by any other means.

=item C<HARNESS_VERSION>

This is the version of Test::Run.

=back

=head1 EXAMPLE

TODO: FIXME

Here's how Test::Run tests itself

  $ cd ~/src/devel/Test-Harness
  $ perl -Mblib -e 'use Test::Run qw(&runtests $verbose);
    $verbose=0; runtests @ARGV;' t/*.t
  Using /home/schwern/src/devel/Test-Harness/blib
  t/base..............ok
  t/nonumbers.........ok
  t/ok................ok
  t/test-harness......ok
  All tests successful.
  Files=4, Tests=24, 2 wallclock secs ( 0.61 cusr + 0.41 csys = 1.02 CPU)

=head1 SEE ALSO

The included F<prove> utility for running test scripts from the command line,
L<Test> and L<Test::Simple> for writing test scripts, L<Benchmark> for
the underlying timing routines, and L<Devel::Cover> for test coverage
analysis.

=head1 TODO

Provide a way of running tests quietly (ie. no printing) for automated
validation of tests.  This will probably take the form of a version
of runtests() which rather than printing its output returns raw data
on the state of the tests.  (Partially done in Test::Run::Straps)

Document the format.

Fix HARNESS_COMPILE_TEST without breaking its core usage.

Figure a way to report test names in the failure summary.

Rework the test summary so long test names are not truncated as badly.
(Partially done with new skip test styles)

Add option for coverage analysis.

Trap STDERR.

Implement Straps total_results()

Remember exit code

Completely redo the print summary code.

Implement Straps callbacks.  (experimentally implemented)

Straps->analyze_file() not taint clean, don't know if it can be

Fix that damned VMS nit.

HARNESS_TODOFAIL to display TODO failures

Add a test for verbose.

Change internal list of test results to a hash.

Fix stats display when there's an overrun.

Fix so perls with spaces in the filename work.

Keeping whittling away at _run_all_tests()

Clean up how the summary is printed.  Get rid of those damned formats.

=head1 BUGS

HARNESS_COMPILE_TEST currently assumes it's run from the Perl source
directory.

Please use the CPAN bug ticketing system at L<http://rt.cpan.org/>.
You can also mail bugs, fixes and enhancements to 
C<< <bug-test-harness >> at C<< rt.cpan.org> >>.

=head1 AUTHORS

Test::Run::Obj is based on L<Test::Harness>, and has later been spinned off
as a separate module.

=head2 Test:Harness Authors

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Numerous anonymous contributors
exist.  Andreas Koenig held the torch for many years, and then
Michael G Schwern.

Test::Harness was then maintained by Andy Lester C<< <andy at petdance.com> >>.

=head2 Test::Run::Obj Authors

Shlomi Fish C<< <shlomif@iglu.org.il> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Core

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Core>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Core>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run>

=back

=head1 SOURCE AVAILABILITY

The latest source of Test::Run is available from its BerliOS Subversion
repository:

L<https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/>

=head1 COPYRIGHT

Copyright 2002-2005
by Michael G Schwern C<< <schwern at pobox.com> >>,
Andy Lester C<< <andy at petdance.com> >>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut
