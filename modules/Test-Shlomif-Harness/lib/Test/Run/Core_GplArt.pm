# -*- Mode: cperl; cperl-indent-level: 4 -*-

package Test::Run::Core_GplArt;

require 5.00405;
use Test::Run::Straps;
use Test::Run::Output;
use Test::Run::Base;
use Test::Run::Assert;

use Test::Run::Obj::FailedObj;
use Test::Run::Obj::TestObj;
use Test::Run::Obj::TotObj;

use Test::Run::Obj::Error;

use Benchmark;
use Config;
use strict;

use Class::Accessor;

use Scalar::Util ();
use List::Util qw(max);
use vars qw(
    @ISA
);

=head1 NAME

Test::Run::Core_GplArt - GPL/Artistic-licensed code of Test::Run::Core.

=cut

@ISA = ('Test::Run::Base');

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

=begin _private

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

sub _init_dir_files
{
    my $self = shift;
    my @dir_files;
    if (defined($self->Leaked_Dir()))
    {
        $self->dir_files($self->_get_dir_files());    
    }  
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
            $self->_report_leaked_files({'leaked_files' => [sort keys %f]});
            $self->dir_files($new_dir_files);
        }
    }
}

sub _get_failed_with_results_seen_msg
{
    my ($self) = @_;
    
    return 
        $self->_is_failed_and_max()
            ? $self->_get_failed_and_max_msg()
            : $self->_get_dont_know_which_tests_failed_msg()
            ;
}

# FWRS == failed_with_results_seen

sub get_common_FWRS_params
{
    my ($self) = @_;

    return
        [
            max     => $self->last_test_obj->max(),
            name    => $self->_get_last_test_filename(),
            estat   => '',
            wstat   => '',
            list_len => $self->list_len(),
        ];
}


sub _get_failed_with_results_seen_params
{
    my ($self) = @_;

    return 
        {
            @{$self->get_common_FWRS_params()},
            @{$self->_get_FWRS_tests_existence_params()},
        }
}

sub _failed_with_results_seen
{
    my ($self) = @_;

    $self->_inc_bad();

    $self->_report_failed_with_results_seen();

    return
        $self->_create_failed_obj_instance(
            $self->_get_failed_with_results_seen_params()
        );
}

sub _get_wstatus
{
    my $self = shift;

    return $self->last_test_results->wait;
}

sub _get_estatus
{
    my $self = shift;

    return $self->last_test_results->exit;
}

sub _get_failed_struct
{
    my ($self) = @_;

    if ($self->_get_wstatus())
    {
         return $self->_dubious_return();
    }
    elsif($self->_is_last_test_seen())
    {
        return $self->_failed_with_results_seen();
    }
    else
    {
        return $self->_failed_before_any_test_output();
    }
}

sub _list_tests_as_failures
{
    my $self = shift;

    my $test = $self->last_test_obj;
    my $results = $self->last_test_results;

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


sub _process_passing_test
{
    my ($self) = @_;

    my $test = $self->last_test_obj;

    # XXX Combine these first two
    if ($test->max() and $test->skipped() + $test->bonus())
    {
        $self->_process_skipped_test();
    }
    elsif ( $test->max() )
    {
        $self->_process_all_ok_test();
    }
    else
    {
        $self->_process_all_skipped_test();
    }
    $self->_tot_inc('good');
}

sub _prepare_for_single_test_run
{
    my ($self, $args) = @_;

    $self->_tot_inc('files');
    $self->Strap()->_seen_header(0);

    $self->_report_single_test_file_start($args);

    return;
}

sub _get_last_test_filename
{
    my $self = shift;

    return $self->last_test_results->filename;
}

sub _add_to_failed_tests
{
    my $self = shift;

    $self->failed_tests()->{$self->_get_last_test_filename()} = 
        $self->_get_failed_struct();

    return;
}

sub _is_test_passing
{
    my $self = shift;

    return $self->last_test_results->passing;
}

sub _process_test_file_results
{
    my ($self) = @_;

    if ($self->_is_test_passing()) 
    {
        $self->_process_passing_test();
    }
    else
    {
        $self->_list_tests_as_failures();
        $self->_add_to_failed_tests();
    }

    return;
}

sub _get_tot_counter_tests
{
    my $self = shift;
    return [tests => (scalar @{$self->test_files()})];
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
        max(
            $self->_get_format_failed_str_len(),
            @{$self->_get_format_tests_namelens()},
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


sub _create_fmts 
{
    my $self = shift;

    $self->_calc_format_widths();

    return 0;
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

sub _get_skipped_bonusmsg
{
    my $self = shift;

    return $self->tot->_get_skipped_bonusmsg();
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

sub _get_dubious_summary
{
    my ($self, $args) = @_;

    my $test = $self->last_test_obj;

    if ($test->max())
    {
        if ($test->next() == $test->max() + 1 and not @{$test->failed()})
        {
            $self->_report_dubious_summary_all_subtests_successful();
            
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
                $self->_get_premature_test_dubious_summary();
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

sub _calc_dubious_return_ret_value
{
    my $self = shift;

    my $dubious_summary = $self->_get_dubious_summary();

    return 
        $self->_create_failed_obj_instance(
            {
                %{$dubious_summary},
                max => $self->last_test_obj->max() || '??',
                estat => $self->_get_estatus(),
                wstat => $self->_get_wstatus(),
                name => $self->_get_last_test_filename(),
            }
        );
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
