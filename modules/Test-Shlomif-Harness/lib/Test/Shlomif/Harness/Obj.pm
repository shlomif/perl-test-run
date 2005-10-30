# -*- Mode: cperl; cperl-indent-level: 4 -*-

package Test::Shlomif::Harness::Obj;

require 5.00405;
use Test::Shlomif::Harness::Straps;
use Test::Shlomif::Harness::Output;
use Test::Harness::Assert;
use Exporter;
use Benchmark;
use Config;
use strict;

use Class::Accessor;

use vars qw(
    $VERSION 
    @ISA @EXPORT @EXPORT_OK 
    $Switches
    $switches
    $Curtest
    $Columns 
    $has_time_hires
);

BEGIN {
    eval "use Time::HiRes 'time'";
    $has_time_hires = !$@;
}

=head1 NAME

Test::Harness - Run Perl standard test scripts with statistics

=head1 VERSION

Version 2.53_02

=cut

$VERSION = "0.0100_02";

# Backwards compatibility for exportable variable names.
# REMOVED *verbose  = *Verbose;
*switches = *Switches;
# REMOVED *debug    = *Debug;

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_NG_VERSION} = $VERSION;

END {
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_NG_VERSION};
}

# Some experimental versions of OS/2 build have broken $?
my $Ignore_Exitcode = $ENV{HARNESS_IGNORE_EXITCODE};

# REMOVED: my $Files_In_Dir = $ENV{HARNESS_FILELEAK_IN_DIR};

@ISA = ('Exporter', 'Class::Accessor');
@EXPORT    = qw(&runtests);
@EXPORT_OK = qw($verbose $switches);

# REMOVED $Verbose  = $ENV{HARNESS_VERBOSE} || 0;
# REMOVED $Debug    = $ENV{HARNESS_DEBUG} || 0;
$Switches = "-w";
$Columns  = $ENV{HARNESS_COLUMNS} || $ENV{COLUMNS} || 80;
$Columns--;             # Some shells have trouble with a full line of text.
# REMOVED $Timer    = $ENV{HARNESS_TIMER} || 0;

__PACKAGE__->mk_accessors(qw(
    _bonusmsg
    Debug
    Leaked_Dir
    Strap
    Timer
    Verbose
    dir_files
    failed_tests
    output
    test_files
    tot
    width
));

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _get_simple_params
{
    return
        [qw(
            Debug
            Leaked_Dir
            Verbose
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
    return Test::Shlomif::Harness::Output->new(
        %$args,
    );
}

sub _initialize
{
    my $self = shift;
    my (%args) = (@_);
    $self->_init_simple_params(\%args);
    $self->dir_files([]);
    $self->output($self->_get_new_output(\%args));
    $self->Strap(
        Test::Shlomif::Harness::Straps->new(
            output => $self->output(),
        )
    );
    $self->Strap()->{callback} = \&strap_callback;
    return 0;
}

=head1 SYNOPSIS

  use Test::Shlomif::Harness::Obj;

  my $tester = Test::Shlomif::Harness::Obj->new();
  $tester->runtests('test_files' => \@test_files);
  

=head1 DESCRIPTION

B<STOP!> If all you want to do is write a test script, consider
using Test::Simple.  Test::Harness is the module that reads the
output from Test::Simple, Test::More and other modules based on
Test::Builder.  You don't need to know about Test::Harness to use
those modules.

Test::Harness runs tests and expects output from the test in a
certain format.  That format is called TAP, the Test Anything
Protocol.  It is defined in L<Test::Harness::TAP>.

C<Test::Harness::runtests(@tests)> runs all the testscripts named
as arguments and checks standard output for the expected strings
in TAP format.

The F<prove> utility is a thin wrapper around Test::Harness.

=head2 Taint mode

Test::Harness will honor the C<-T> or C<-t> in the #! line on your
test files.  So if you begin a test with:

    #!perl -T

the test will be run with taint mode on.

=head2 Object Parameters

=over 4

=item C<$self-E<gt>Verbose()>

The object variable C<$self-E<gt>Verbose()> can be used to let C<runtests()> 
display the standard output of the script without altering the behavior 
otherwise.  The F<prove> utility's C<-v> flag will set this.

=back 

=head2 Configuration variables.

These variables can be used to configure the behavior of
Test::Harness.  They are exported on request.

=over 4


=item C<$Test::Harness::switches>

The package variable C<$Test::Harness::switches> is exportable and can be
used to set perl command line options used for running the test
script(s). The default value is C<-w>. It overrides C<HARNESS_SWITCHES>.

=item C<$Test::Harness::Timer>

If set to true, and C<Time::HiRes> is available, print elapsed seconds
after each test file.

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

Test::Harness currently only has one function, here it is.

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

sub runtests {
    my $self = shift;
    my (%args) = (@_);

    local ($\, $,);

    my($failedtests) =
        $self->_run_all_tests();
    $self->_show_results();

    my $ok = $self->_all_ok($self->tot());

    assert(($ok xor keys %$failedtests), 
           q{ok status jives with $failedtests});

    return $ok;
}

=begin _private

=item B<_all_ok>

  my $ok = $self->_all_ok(\%tot);

Tells you if this test run is overall successful or not.

=cut

sub _all_ok {
    my $self = shift;
    my $tot = shift;

    return $tot->{bad} == 0 && ($tot->{max} || $tot->{skipped}) ? 1 : 0;
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
    my ($self, $field, $difference) = @_;
    $self->tot()->{$field} += $difference;
}

sub _tot_inc
{
    my ($self, $field) = @_;
    $self->_tot_add($field,1);
}

sub _failed_with_results_seen
{
    my ($self, %args) = @_;
    my $test = $args{'test_struct'};
    my $tfile = $args{'filename'};

    $self->_tot_inc('bad'); 
    if (@{$test->{failed}} and $test->{max}) {
        my ($txt, $canon) =
            $self->_canonfailed(
                $test->{max},
                $test->{skipped},
                $test->{failed}
            );
        $self->_print_message("$test->{ml}$txt");
        return 
            +{
                canon   => $canon,
                max     => $test->{max},
                failed  => scalar @{$test->{failed}},
                name    => $tfile, 
                percent => 100*(scalar @{$test->{failed}})/$test->{max},
                estat   => '',
                wstat   => '',
            };
    }
    else {
        $self->_print_message("Don't know which tests failed: got $test->{ok} ok, ".
              "expected $test->{max}");
        return
            +{
                canon   => '??',
                max     => $test->{max},
                failed  => '??',
                name    => $tfile, 
                percent => undef,
                estat   => '', 
                wstat   => '',
           };
    }    
}

sub _failed_before_any_test_output
{
    my ($self, %args) = @_;
    my $tfile = $args{'filename'};

    $self->_print_message("FAILED before any test output arrived");
    $self->_tot_inc('bad');
    return 
        +{ 
            canon       => '??',
            max         => '??',
            failed      => '??',
            name        => $tfile,
            percent     => undef,
            estat       => '', 
            wstat       => '',
         };
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
    if ($test->{'next'} <= $test->{max}) {
        push @{$test->{failed}}, $test->{'next'}..$test->{max};
    }
    # List overruns as failures.
    else {
        my $details = $results->{details};
        foreach my $overrun ($test->{max}+1..@$details) {
            next unless ref $details->[$overrun-1];
            push @{$test->{failed}}, $overrun
        }
    }
}

sub _tot_add_results
{
    my $self = shift;
    my $results = shift;

    foreach my $type (qw(bonus max ok todo))
    {
        $self->_tot_add($type => $results->{$type});
    }
    $self->_tot_add(sub_skipped => $results->{skip});
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
    my %results = $self->Strap()->analyze_file($tfile) or
      do { warn $self->Strap()->{error}, "\n";  next };
    my $elapsed = $self->_get_elapsed('start_time' => $test_start_time);
    return (\%results, $elapsed);
}

sub _process_passing_test
{
    my $self = shift;
    my (%args) = @_;

    my $test = $args{test_struct};
    my $elapsed = $args{elapsed};

    # XXX Combine these first two
    if ($test->{max} and $test->{skipped} + $test->{bonus}) {
        my @msg;
        push(@msg, "$test->{skipped}/$test->{max} skipped: ". 
            $test->{skip_reason})
            if $test->{skipped};
        push(@msg, "$test->{bonus}/$test->{max} unexpectedly succeeded")
            if $test->{bonus};
        $self->_print_message("$test->{ml}ok$elapsed\n        ".
            join(', ', @msg));
    }
    elsif ( $test->{max} ) {
        $self->_print_message("$test->{ml}ok$elapsed");
    }
    else {
        $self->_print_message("skipped\n        all skipped: " .
            ((defined($test->{skip_all}) && length($test->{skip_all})) ?
                $test->{skip_all} :
                "no reason given")
            );
        $self->_tot_inc('skipped');
    }
    $self->_tot_inc('good');
}

sub _get_test_struct
{
    my $self = shift;
    my $results = shift;

    $self->_tot_add_results($results);

    return 
        {
            ok          => $results->{ok},
            'next'      => $self->Strap()->{'next'},
            max         => $results->{max},
            # state of the current test.
            failed      => [
                grep { !$results->{details}[$_-1]{ok} }
                 (1 .. @{$results->{details}})
                           ],
            bonus       => $results->{bonus},
            skipped     => $results->{skip},
            skip_reason => $results->{skip_reason},
            skip_all    => $self->Strap()->{skip_all},
            ml          => $self->output()->ml(),
        };
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

sub _get_tot_counter_fields
{
    my $self = shift;
    return [qw(bonus max ok files bad good sub_skipped todo skipped bench)];
}

sub _get_tot_counter_kv
{
    my $self = shift;
    return [map { $_ => 0 } @{$self->_get_tot_counter_fields()}];
}

sub _get_tot_counter_tests
{
    my $self = shift;
    return [tests => (scalar @{$self->test_files()})];
}

sub _init_tot
{
    my $self = shift;
    # Test-wide totals.
    $self->tot({
            @{$self->_get_tot_counter_kv()},
            @{$self->_get_tot_counter_tests()},
            });
}

sub _run_all_tests {
    my $self = shift;
    my (%args) = @_;

    my $tests = $self->test_files();

    _autoflush(\*STDOUT);
    _autoflush(\*STDERR);

    $self->failed_tests({});

    $self->_init_tot();

    $self->_init_dir_files();
    my $run_start_time = new Benchmark;

    $self->width($self->_leader_width('test_files' => $tests));
    foreach my $tfile (@$tests) 
    {
        $self->_run_single_test('test_file' => $tfile);
    } # foreach test
    $self->tot()->{bench} = timediff(new Benchmark, $run_start_time);

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
    my ($self, %args) = @_;
    my $tests = $args{test_files};

    my $maxlen = 0;
    my $maxsuflen = 0;
    foreach (@$tests) {
        my $suf    = /\.(\w+)$/ ? $1 : '';
        my $len    = length;
        my $suflen = length $suf;
        $maxlen    = $len    if $len    > $maxlen;
        $maxsuflen = $suflen if $suflen > $maxsuflen;
    }
    # + 3 : we want three dots between the test name and the "ok"
    return $maxlen + 3 - $maxsuflen;
}

sub _report_success
{
    my $self = shift;
    $self->_print_message("All tests successful" . $self->_get_bonusmsg() . ".");
}

sub _fail_no_tests_run
{
    die "FAILED--no tests were run for some reason.\n";
}

sub _fail_no_tests_output
{
    my $self = shift;
    my $tot = $self->tot();
    my $blurb = $tot->{tests}==1 ? "script" : "scripts";
    die "FAILED--$tot->{tests} test $blurb could be run, ".
        "alas--no output ever seen\n";
}

sub _print_final_stats
{
    my ($self) = @_;
    my $tot = $self->tot();
    $self->output()->print_message(
        sprintf("Files=%d, Tests=%d, %s",
           $tot->{files}, $tot->{max}, timestr($tot->{bench}, 'nop'))
       );
}

sub _get_tests_good_percent
{
    my ($self) = @_;
    return sprintf("%.2f", $self->tot()->{good} / $self->tot()->{tests} * 100);
}

sub _get_sub_percent_msg
{
    my $self = shift;
    my $tot = $self->tot();
    my $percent_ok = 100*$tot->{ok}/$tot->{max};
    return sprintf(" %d/%d subtests failed, %.2f%% okay.",
        $tot->{max} - $tot->{ok}, $tot->{max}, 
        $percent_ok
        );
}

sub _fail_other
{
    my $self = shift;
    my $tot = $self->tot();
    my $failed_tests = $self->failed_tests();

    my $subpct = $self->_get_sub_percent_msg();

    # Now write to formats
    for my $script (sort keys %$failed_tests) {
      $Curtest = $failed_tests->{$script};
      write;
    }
    if ($tot->{bad}) {
        my $bonusmsg = $self->_bonusmsg();
        $bonusmsg =~ s/^,\s*//;
        if ($bonusmsg)
        {
            $self->_print_message("$bonusmsg.");
        }
        die "Failed $tot->{bad}/$tot->{tests} test scripts, " . 
            $self->_get_tests_good_percent() . "% okay.".
            "$subpct\n";
    }
}

sub _show_results {
    my($self) = @_;
    my $tot = $self->tot();

    if ($self->_all_ok($tot)) {
        $self->_report_success();
    }
    elsif (!$tot->{tests}){
        $self->_fail_no_tests_run();
    }
    elsif (!$tot->{max}) {
        $self->_fail_no_tests_output();
    }
    else {
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

    my $curr = $totals->{seen};
    my $next = $self->{'next'};
    my $max  = $totals->{max};
    my $detail = $totals->{details}[-1];

    if( $detail->{ok} ) {
        $self->output()->print_ml_less("ok $curr/$max");

        if( $detail->{type} eq 'skip' ) {
            $totals->{skip_reason} = $detail->{reason}
              unless defined $totals->{skip_reason};
            $totals->{skip_reason} = 'various reasons'
              if $totals->{skip_reason} ne $detail->{reason};
        }
    }
    else {
        $self->output()->print_ml("NOK $curr");
    }

    if( $curr > $next ) {
        $self->output()->print_message("Test output counter mismatch [test $curr]");
    }
    elsif( $curr < $next ) {
        $self->output()->print_message("Confused test output: test $curr answered after ".
              "test ", $next - 1);
    }

};

sub bailout_handler {
    my($self, $line, $type, $totals) = @_;

    die "FAILED--Further testing stopped" .
      ($self->{bailout_reason} ? ": $self->{bailout_reason}\n" : ".\n");
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

    my $sub_skipped_msg =
        "$tot->{sub_skipped} subtest" . $self->_get_s($tot->{sub_skipped});
    if ($tot->{skipped}) {
        return 
            ", $tot->{skipped} test" .
            $self->_get_s($tot->{skipped}) .
            ($tot->{sub_skipped} ? (" and " . $sub_skipped_msg) : "") .
            ' skipped'
            ;
    }
    elsif ($tot->{sub_skipped}) {
        return "$sub_skipped_msg skipped";
    }
}

sub _get_bonusmsg {
    my($self) = @_;
    my $tot = $self->tot();

    if (defined($self->_bonusmsg()))
    {
        return $self->_bonusmsg();
    }

    my $bonusmsg = '';
    $bonusmsg = (" ($tot->{bonus} subtest".($tot->{bonus} > 1 ? 's' : '').
               " UNEXPECTEDLY SUCCEEDED)")
        if $tot->{bonus};

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
        sprintf("$test->{ml}dubious\n\tTest returned status $estatus ".
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
    my $tot = $self->tot();
    my $estatus = $args{'estatus'};
    my $wstatus = $args{'wstatus'};
    my $filename = $args{'filename'};
    
    my ($failed, $canon, $percent) = ('??', '??');

    $self->_print_dubious(%args);

    $tot->{bad}++;

    if ($test->{max}) {
        if ($test->{'next'} == $test->{max} + 1 and not @{$test->{failed}}) {
            $self->_print_message("\tafter all the subtests completed successfully");
            $percent = 0;
            $failed = 0;        # But we do not set $canon!
        }
        else {
            push @{$test->{failed}}, $test->{'next'}..$test->{max};
            $failed = @{$test->{failed}};
            (my $txt, $canon) =
                $self->_canonfailed(
                    $test->{max},
                    $test->{skipped},
                    $test->{failed}
                );
            $percent = 100*(scalar @{$test->{failed}})/$test->{max};
            $self->_print_message("DIED. ", $txt);
        }
    }

    return { canon => $canon,  max => $test->{max} || '??',
             failed => $failed,
             percent => $percent,
             estat => $estatus, wstat => $wstatus,
             name => $filename,
           };
}

sub filter_failed
{
    my ($self, $failed_ref) = @_;
    my %seen;
    return [ sort {$a <=> $b} grep !$seen{$_}++, @$failed_ref ];
}

sub _canonfailed ($$$@) {
    my ($self, $max, $skipped, $failed_in) = @_;
    my %seen;
    my $failed = $self->filter_failed($failed_in); 
    my $failed_num = @$failed;
    my @result = ();
    my @canon = ();
    my $min;
    my $last = $min = shift @$failed;
    my $canon;
    if (@$failed) {
        for (@$failed, $failed->[-1]) { # don't forget the last one
            if ($_ > $last+1 || $_ == $last) {
                push @canon, ($min == $last) ? $last : "$min-$last";
                $min = $_;
            }
            $last = $_;
        }
        local $" = ", ";
        push @result, "FAILED tests @canon\n";
        $canon = join ' ', @canon;
    }
    else {
        push @result, "FAILED test $last\n";
        $canon = $last;
    }

    push @result, "\tFailed $failed_num/$max tests, ";
    if ($max) {
        push @result, sprintf("%.2f",100*(1-$failed_num/$max)), "% okay";
    }
    else {
        push @result, "?% okay";
    }
    my $ender = 's' x ($skipped > 1);
    if ($skipped) {
        my $good = $max - $failed_num - $skipped;
        my $skipmsg = " (less $skipped skipped test$ender: $good okay, ";
        if ($max) {
            my $goodper = sprintf("%.2f",100*($good/$max));
            $skipmsg .= "$goodper%)";
        }
        else {
            $skipmsg .= "?%)";
        }
        push @result, $skipmsg;
    }
    my $txt = join "", @result;
    return ($txt, $canon);
}

=end _private

=back

=cut


1;
__END__


=head1 EXPORT

C<&runtests> is exported by Test::Harness by default.

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

Test::Harness sets these before executing the individual tests.

=over 4

=item C<HARNESS_ACTIVE>

This is set to a true value.  It allows the tests to determine if they
are being executed through the harness or by any other means.

=item C<HARNESS_VERSION>

This is the version of Test::Harness.

=back

=head1 ENVIRONMENT VARIABLES THAT AFFECT TEST::HARNESS

=over 4

=item C<HARNESS_COLUMNS>

This value will be used for the width of the terminal. If it is not
set then it will default to C<COLUMNS>. If this is not set, it will
default to 80. Note that users of Bourne-sh based shells will need to
C<export COLUMNS> for this module to use that variable.

=item C<HARNESS_COMPILE_TEST>

When true it will make harness attempt to compile the test using
C<perlcc> before running it.

B<NOTE> This currently only works when sitting in the perl source
directory!

=item C<HARNESS_DEBUG>

If true, Test::Harness will print debugging information about itself as
it runs the tests.  This is different from C<HARNESS_VERBOSE>, which prints
the output from the test being run.  Setting C<$Test::Harness::Debug> will
override this, or you can use the C<-d> switch in the F<prove> utility.

=item C<HARNESS_FILELEAK_IN_DIR>

When set to the name of a directory, harness will check after each
test whether new files appeared in that directory, and report them as

  LEAKED FILES: scr.tmp 0 my.db

If relative, directory name is with respect to the current directory at
the moment runtests() was called.  Putting absolute path into 
C<HARNESS_FILELEAK_IN_DIR> may give more predictable results.

=item C<HARNESS_IGNORE_EXITCODE>

Makes harness ignore the exit status of child processes when defined.

=item C<HARNESS_NOTTY>

When set to a true value, forces it to behave as though STDOUT were
not a console.  You may need to set this if you don't want harness to
output more frequent progress messages using carriage returns.  Some
consoles may not handle carriage returns properly (which results in a
somewhat messy output).

=item C<HARNESS_PERL>

Usually your tests will be run by C<$^X>, the currently-executing Perl.
However, you may want to have it run by a different executable, such as
a threading perl, or a different version.

If you're using the F<prove> utility, you can use the C<--perl> switch.

=item C<HARNESS_PERL_SWITCHES>

Its value will be prepended to the switches used to invoke perl on
each test.  For example, setting C<HARNESS_PERL_SWITCHES> to C<-W> will
run all tests with all warnings enabled.

=item C<HARNESS_VERBOSE>

If true, Test::Harness will output the verbose results of running
its tests.  Setting C<$Test::Harness::verbose> will override this,
or you can use the C<-v> switch in the F<prove> utility.

=back

=head1 EXAMPLE

Here's how Test::Harness tests itself

  $ cd ~/src/devel/Test-Harness
  $ perl -Mblib -e 'use Test::Harness qw(&runtests $verbose);
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
on the state of the tests.  (Partially done in Test::Harness::Straps)

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

Either Tim Bunce or Andreas Koenig, we don't know. What we know for
sure is, that it was inspired by Larry Wall's TEST script that came
with perl distributions for ages. Numerous anonymous contributors
exist.  Andreas Koenig held the torch for many years, and then
Michael G Schwern.

Current maintainer is Andy Lester C<< <andy at petdance.com> >>.

=head1 COPYRIGHT

Copyright 2002-2005
by Michael G Schwern C<< <schwern at pobox.com> >>,
Andy Lester C<< <andy at petdance.com> >>.

This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>.

=cut
