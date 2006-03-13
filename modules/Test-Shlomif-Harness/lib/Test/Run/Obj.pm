# -*- Mode: cperl; cperl-indent-level: 4 -*-

package Test::Run::Obj;

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

Test::Run::Obj - Run Perl standard test scripts with statistics

=head1 VERSION

Version 0.0100_06

=cut

$VERSION = "0.0100_07";

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

sub _get_new_output
{
    my $self = shift;
    my $args = shift;
    return Test::Run::Output->new(
        %$args,
    );
}

sub _initialize
{
    my $self = shift;
    my (%args) = (@_);
    $self->Columns(80);
    $self->Switches("-w");
    $self->_init_simple_params(\%args);
    $self->dir_files([]);
    $self->output($self->_get_new_output(\%args));
    $self->Strap(
        Test::Run::Straps->new(
            output => $self->output(),
        )
    );
    $self->Strap()->callback(\&strap_callback);
    return 0;
}

=head1 SYNOPSIS

  use Test::Run::Obj;

  my $tester = Test::Run::Obj->new('test_files' => \@test_files);
  $tester->runtests();

=head1 DESCRIPTION

B<STOP!> If all you want to do is write a test script, consider
using Test::Simple.  Test::Run::Obj is the module that reads the
output from Test::Simple, Test::More and other modules based on
Test::Builder.  You don't need to know about Test::Run::Obj to use
those modules.

Test::Run::Obj runs tests and expects output from the test in a
certain format.  That format is called TAP, the Test Anything
Protocol.  It is defined in L<Test::Harness::TAP>.

C<$tester->runtests(@tests)> runs all the testscripts named
as arguments and checks standard output for the expected strings
in TAP format.

Test::Run::Obj provides a programmer API for running and analyzing
the output of TAP files. For calling from the command line, look at
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
        'test_files' => \@mytests,
        'Verbose' => 1,
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

=head2 Configuration variables.

These variables can be used to configure the behavior of
Test::Run.  They are exported on request.

=over 4


=item C<$Test::Run::switches>

The package variable C<$Test::Run::switches> is exportable and can be
used to set perl command line options used for running the test
script(s). The default value is C<-w>. It overrides C<HARNESS_SWITCHES>.

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

Test::Run currently only has one function, here it is.

=over 4

=item B<runtests>

  my $allok = $self->runtests('test_files' => \@test_files);

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

sub _handle_runtests_error
{
    my $self = shift;
    my (%args) = @_;
    my $error = $args{'error'};

    if (UNIVERSAL::isa($error, "Test::Run::Obj::Error::TestsFail"))
    {
        die $error->text();
    }
    else
    {
        die $error;
    }
}

sub runtests
{
    my $self = shift;

    local ($\, $,);

    my $ok = eval { $self->_real_runtests(@_) };
    if ($@)
    {
        return $self->_handle_runtests_error(
            'ok' => $ok, 
            'error' => $@,
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

sub _report_leaked_files
{
    my ($self, $files) = (@_);
    my @f = sort @$files;
    $self->_print_message("LEAKED FILES: @f");
}

sub _recheck_dir_files
{
    my $self = shift;
    
    if (defined $self->Leaked_Dir()) {
        my $new_dir_files = $self->_get_dir_files();
        if (@$new_dir_files != @{$self->dir_files()}) {
            my %f;
            @f{@$new_dir_files} = (1) x @$new_dir_files;
            delete @f{@{$self->dir_files()}};
            $self->_report_leaked_files([sort keys %f]);
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
    return Test::Run::Obj::FailedObj->new(
        @_
    );
}
sub _failed_with_results_seen
{
    my ($self, %args) = @_;
    my $test = $args{'test_struct'};
    my $tfile = $args{'filename'};

    $self->_tot_inc('bad'); 
    if (@{$test->failed()} and $test->max()) {
        my ($txt, $canon) = $self->_canonfailed($test);
        $self->_print_message($test->ml().$txt);
        return $self->_create_failed_obj_instance(
                canon   => $canon,
                max     => $test->max(),
                failed  => scalar @{$test->failed()},
                name    => $tfile, 
                percent => 100*(scalar @{$test->failed()})/$test->max(),
                estat   => '',
                wstat   => '',
            );
    }
    else {
        $self->_print_message("Don't know which tests failed: got " . $test->ok() . " ok, ".
              "expected " . $test->max());
        return $self->_create_failed_obj_instance(
                canon   => '??',
                max     => $test->max(),
                failed  => '??',
                name    => $tfile, 
                percent => undef,
                estat   => '', 
                wstat   => '',
            );
    }    
}

sub _failed_before_any_test_output
{
    my ($self, %args) = @_;
    my $tfile = $args{'filename'};

    $self->_print_message("FAILED before any test output arrived");
    $self->_tot_inc('bad');
    return $self->_create_failed_obj_instance(
            canon       => '??',
            max         => '??',
            failed      => '??',
            name        => $tfile,
            percent     => undef,
            estat       => '', 
            wstat       => '',
        );
}

sub _get_failed_struct
{
    my ($self, %args) = @_;
    if ($args{'wstatus'}) {
         return
            $self->_dubious_return(
                %args
                );
    }
    elsif($args{'results'}->{seen}) {
        return
            $self->_failed_with_results_seen(
                %args,
            );
    }
    else {
        return
            $self->_failed_before_any_test_output(
                %args,
            );
    }
}

sub _list_tests_as_failures
{
    my $self = shift;
    my (%args) = @_;

    my $test = $args{test_struct};
    my $results = $args{results};

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
    my $self = shift;
    my (%args) = @_;

    if ( $self->Timer() ) {
        my $elapsed = time - $args{start_time};
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

sub _time_single_test
{
    my $self = shift;
    my $tfile = shift;

    my $test_start_time = $self->Timer() ? time : 0;
    $self->Strap()->Verbose($self->Verbose());
    $self->Strap()->Debug($self->Debug());
    $self->Strap()->Test_Interpreter($self->Test_Interpreter());
    $self->Strap()->Switches($self->Switches());
    $self->Strap()->Switches_Env($self->Switches_Env());
    my $results = $self->Strap()->analyze_file($tfile) or
      do { warn $self->Strap()->{error}, "\n";  next };
    my $elapsed = $self->_get_elapsed('start_time' => $test_start_time);
    return ($results, $elapsed);
}

sub _process_passing_test
{
    my $self = shift;
    my (%args) = @_;

    my $test = $args{test_struct};
    my $elapsed = $args{elapsed};

    # XXX Combine these first two
    if ($test->max() and $test->skipped() + $test->bonus()) {
        my @msg;
        push(@msg, $test->skipped()."/".$test->max()." skipped: ". 
            $test->skip_reason())
            if $test->skipped();
        push(@msg, $test->bonus()."/".$test->max()." unexpectedly succeeded")
            if $test->bonus();
        $self->_print_message($test->ml()."ok$elapsed\n        ".
            join(', ', @msg));
    }
    elsif ( $test->max() ) {
        $self->_print_message($test->ml()."ok$elapsed");
    }
    else {
        $self->_print_message("skipped\n        all skipped: " .
            ((defined($test->skip_all()) && length($test->skip_all())) ?
                $test->skip_all() :
                "no reason given")
            );
        $self->_tot_inc('skipped');
    }
    $self->_tot_inc('good');
}

sub _create_test_obj_instance
{
    my $self = shift;
    return Test::Run::Obj::TestObj->new(@_);
}

sub _get_test_struct
{
    my $self = shift;
    my $results = shift;

    $self->_tot_add_results($results);

    return 
        $self->_create_test_obj_instance(
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
            skip_all    => $self->Strap()->{skip_all},
            ml          => $self->output()->ml(),
        );
}

sub _run_single_test
{
    my ($self, %args) = @_;
    my $tfile = $args{'test_file'};

    $self->output()->last_test_print(0); # so each test prints at least once
    $self->output()->print_leader(
        filename => $tfile,
        width => $self->width(),
    );

    $self->_tot_inc('files');

    $self->Strap()->{_seen_header} = 0;
    if ( $self->Debug() ) {
        $self->_print_message("# Running: " . $self->Strap()->_command_line($tfile));
    }
    my ($results, $elapsed) = $self->_time_single_test($tfile);

    my $test = $self->_get_test_struct($results);

    my($estatus, $wstatus) = @{$results}{qw(exit wait)};

    if ($results->{passing}) 
    {
        $self->_process_passing_test(
            test_struct => $test,
            elapsed => $elapsed,
        );
    }
    else {
        $self->_list_tests_as_failures(
            'test_struct' => $test,
            'results' => $results,
        ); 
        $self->failed_tests()->{$tfile} = 
            $self->_get_failed_struct(
                test_struct => $test,
                estatus => $estatus,
                wstatus => $wstatus,
                filename => $tfile,
                results => $results,
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
        @{$self->_get_tot_counter_tests()},
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
    my (%args) = @_;

    _autoflush(\*STDOUT);
    _autoflush(\*STDERR);

    $self->failed_tests({});

    $self->_init_tot();

    $self->_init_dir_files();
    my $run_start_time = new Benchmark;

    $self->width($self->_leader_width());
    foreach my $tfile (@{$self->test_files()}) 
    {
        $self->_run_single_test('test_file' => $tfile);
    } # foreach test
    $self->tot()->bench(timediff(new Benchmark, $run_start_time));

    $self->Strap()->_restore_PERL5LIB;

    # TODO: Eliminate this? -- Shlomi Fish
    return $self->failed_tests();
}


=item B<_leader_width>

  my($width) = $self->_leader_width('test_files' => \@test_files);

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


=head2 $self->_report('channel' => $channel, 'msg' => $message);

Reports the C<$message> message to channel C<$channel>. This can be overrided
by derived classes to do alternate functionality besides calling 
_print_message(), also different based on the channel.
Currently available channels are:

=over 4

=item 'success'

The success report.

=back

=cut

sub _report
{
    my $self = shift;
    my (%args) = @_;
    my $msg = $args{'msg'};
    return $self->_print_message($msg);    
}

sub _get_success_msg
{
    my $self = shift;
    return "All tests successful" . $self->_get_bonusmsg() . ".";
}

sub _report_success
{
    my $self = shift;
    $self->_report(
        'channel' => "success",
        'msg' => $self->_get_success_msg(),
    );
}

sub _get_fail_no_tests_run_text
{
    return "FAILED--no tests were run for some reason.\n"
}

sub _fail_no_tests_run
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail->new(
        text => $self->_get_fail_no_tests_run_text(),
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
    die Test::Run::Obj::Error::TestsFail->new(
        text => $self->_get_fail_no_tests_output_text(),
    );
}

sub _print_final_stats
{
    my ($self) = @_;
    my $tot = $self->tot();
    $self->output()->print_message(
        sprintf("Files=%d, Tests=%d, %s",
           $tot->files(), $tot->max(), timestr($tot->bench(), 'nop'))
       );
}

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
    my ($self, %args) = (@_);
    my $max_nl_ref = $args{max_namelen};

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

    my $list_len = $self->_get_fmt_list_len('max_namelen' => \$max_namelen);

    $self->max_namelen($max_namelen);
    $self->list_len($list_len);

    return 0;
}

sub _fail_other_print_top
{
    my $self = shift;

    my $max_namelen = $self->max_namelen();

    $self->_print_message(
        sprintf("%-${max_namelen}s", $self->_get_format_failed_str()) .
        $self->_get_format_middle_str() .
        $self->_get_format_list_str()
    );
    $self->_print_message("-" x $self->format_columns());
}

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

sub _fail_other_print_test
{
    my $self = shift;
    my $script = shift;
    my $test = $self->failed_tests()->{$script};

    my $max_namelen = $self->max_namelen();
    my $list_len = $self->list_len();

    my @canon = split(/\s+/, $test->canon());

    my $canon_strings = $self->_fail_other_get_canon_strings([@canon]);
    
    $self->_print_message(
        sprintf(
            ("%-" . $max_namelen . "s  " . 
                "%3s %5s %5s %4s %6.2f%%  %s"),
            $test->name(), $test->estat(),
            $test->wstat(), $test->max(),
            $test->failed(), $test->percent(),
            shift(@$canon_strings)
        )
    );
    foreach my $c (@$canon_strings)
    {
        $self->_print_message(
            sprintf((" " x ($self->format_columns() - $list_len) . 
                "%s"),
                $c
            ),
        );
    }
}

sub _create_fmts 
{
    my $self = shift;
    my $failedtests = $self->failed_tests();

    $self->_calc_format_widths();

    return 0;
}

sub _get_fail_other_exception_text
{
    my $self = shift;
    return "Failed " . $self->tot()->bad() . "/" .
        $self->tot()->tests(). " test scripts, " .
        $self->_get_tests_good_percent() . "% okay." .
        $self->_get_sub_percent_msg() . "\n";
}

sub _fail_other_throw_exception
{
    my $self = shift;

    die Test::Run::Obj::Error::TestsFail->new(
        text => $self->_get_fail_other_exception_text(),
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
         $self->_fail_other_print_test($script);
    }
}

sub _fail_other_print_bonus_message
{
    my $self = shift;
    
    my $bonusmsg = $self->_bonusmsg() || "";
    $bonusmsg =~ s/^,\s*//;
    if ($bonusmsg)
    {
        $self->_print_message("$bonusmsg.");
    }
}

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
    $self->_print_final_stats();
}


my %Handlers = (
    header => \&header_handler,
    test => \&test_handler,
    bailout => \&bailout_handler,
);

sub strap_callback {
    my($self, $line, $type, $totals) = @_;
    print $line if $self->Verbose();

    my $meth = $Handlers{$type};
    $meth->($self, $line, $type, $totals) if $meth;
};


sub header_handler {
    my($self, $line, $type, $totals) = @_;

    warn "Test header seen more than once!\n" if $self->{_seen_header};

    $self->{_seen_header}++;

    warn "1..M can only appear at the beginning or end of tests\n"
      if $totals->{seen} && 
         $totals->{max}  < $totals->{seen};
};

sub test_handler {
    my($self, $line, $type, $totals) = @_;

    my $curr = $totals->seen();
    my $next = $self->next();
    my $max  = $totals->max();
    my $detail = $totals->details()->[-1];

    if( $detail->ok() ) {
        $self->output()->print_ml_less("ok $curr/$max");

        $totals->update_skip_reason($detail);
    }
    else {
        $self->output()->print_ml("NOK $curr");
    }

    if( $curr > $next ) {
        $self->output()->print_message("Test output counter mismatch [test $curr]");
    }
    elsif( $curr < $next ) {
        $self->output()->print_message(
            "Confused test output: test $curr answered after test " . 
            ($next - 1)
        );
    }

};

sub bailout_handler {
    my($self, $line, $type, $totals) = @_;

    die "FAILED--Further testing stopped" .
      ($self->bailout_reason() ? ": " . $self->bailout_reason() . "\n" : ".\n");
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

sub _print_message
{
    my $self = shift;
    $self->output()->print_message(@_);
}

sub _print_dubious
{
    my $self = shift;
    my (%args) = @_;
    my $test = $args{test_struct};
    my $estatus = $args{estatus};
    $self->_print_message(
        sprintf($test->ml()."dubious\n\tTest returned status $estatus ".
            "(wstat %d, 0x%x)",
            (($args{'wstatus'}) x 2))
        );
    if ($^O eq "VMS")
    {
        $self->_print_message("\t\t(VMS status is $estatus)");
    }        
}

# Test program go boom.
sub _dubious_return {
    my ($self,%args) = @_;
    my $test = $args{'test_struct'};
    my $estatus = $args{'estatus'};
    my $wstatus = $args{'wstatus'};
    my $filename = $args{'filename'};
    
    my ($failed, $canon, $percent) = ('??', '??');

    $self->_print_dubious(%args);

    $self->_tot_inc('bad');

    if ($test->max()) {
        if ($test->next() == $test->max() + 1 and not @{$test->failed()}) {
            $self->_print_message("\tafter all the subtests completed successfully");
            $percent = 0;
            $failed = 0;        # But we do not set $canon!
        }
        else {
            $test->add_to_failed($test->next()..$test->max());
            $failed = @{$test->failed()};
            my $txt;
            ($txt, $canon) = $self->_canonfailed($test);
            $percent = 100*(scalar @{$test->failed()})/$test->max();
            $self->_print_message("DIED. " . $txt);
        }
    }

    return 
        $self->_create_failed_obj_instance(
            canon => $canon,
            max => $test->max() || '??',
            failed => $failed,
            percent => $percent,
            estat => $estatus,
            wstat => $wstatus,
            name => $filename,
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
    my ($self, %args) = @_;
    my $failed_in = $args{failed_in};
    my $failed = $self->filter_failed($failed_in);
    my $failed_num = @$failed;

    my $canon = $self->_canonfailed_get_canon_helper($failed);
    return Test::Run::Obj::CanonFailedObj->new(
        canon => join(' ', @$canon),
        result => [$self->_get_failed_string($canon)],
        failed_num => $failed_num,
    );
}

sub _canonfailed {
    my ($self, $test) = @_;

    my $canon_obj =
        $self->_canonfailed_get_canon(
            'failed_in' => $test->failed(),
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

C<&runtests> is exported by Test::Run by default.

C<$verbose>, C<$switches> and C<$debug> are exported upon request.

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

=head1 COPYRIGHT

Copyright 2002-2005
by Michael G Schwern C<< <schwern at pobox.com> >>,
Andy Lester C<< <andy at petdance.com> >>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut
