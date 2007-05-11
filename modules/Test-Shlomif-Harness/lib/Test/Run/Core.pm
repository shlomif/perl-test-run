package Test::Run::Core;

use strict;
use warnings;

use base 'Test::Run::Core_GplArt';

use vars qw($VERSION);

use List::MoreUtils ();


=head1 NAME

Test::Run::Core - Base class to run standard TAP scripts.

=head1 VERSION

Version 0.0110

=cut

$VERSION = '0.0110';

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_NG_VERSION} = $VERSION;

END
{
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_NG_VERSION};
}

__PACKAGE__->mk_accessors(@{__PACKAGE__->_get_simple_params()});

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
            test_files
            Test_Interpreter
            Timer
            Verbose
       )];
}

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

=head2 METHODS

Test::Run currently has only one interface method.

=head2 $tester->runtests()

    my $all_ok = $tester->runtests()

Runs the tests, see if they are OK. Returns true if they are OK, or
throw an exception otherwise.

=cut

=head2 $self->_report_leaked_files({leaked_files => [@files]})

[This is a method that needs to be over-rided.]

Should report (or ignore) the files that were leaked in the directories
that were specifies as leaking directories.

=cut

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

sub _calc_strap_callback_map
{
    return 
    {
        "tap_event"        => "_tap_event_strap_callback",
        "report_start_env" => "_report_script_start_environment",
        "could_not_run_script" => "_report_could_not_run_script",
        "test_file_opening_error" => "_handle_test_file_opening_error",
        "test_file_closing_error" => "_handle_test_file_closing_error",
    };
}

sub _strap_callback
{
    my ($self, $args) = @_;
    
    my $type = $args->{type};
    my $cb = $self->_calc_strap_callback_map()->{$type};

    return $self->$cb($args);
}

sub filter_failed
{
    my ($self, $failed_ref) = @_;
    return [ List::MoreUtils::uniq(sort { $a <=> $b } @$failed_ref) ];
}

sub _canonfailed_get_failed
{
    my $self = shift;

    return $self->filter_failed($self->_get_failed_list());
}

sub _get_failed_list
{
    my $self = shift;

    return $self->last_test_obj->failed;
}

=head2 $self->_report_failed_before_any_test_output();

[This is a method that needs to be over-rided.]

=cut

=head2 $self->_report_skipped_test()

[This is a method that needs to be over-rided.]

Should report the skipped test.

=cut

=head2 $self->_report_all_ok_test()

[This is a method that needs to be over-rided.]

Should report the all OK test.

=cut

=head2 $self->_report_all_skipped_test()

[This is a method that needs to be over-rided.]

Should report the all-skipped test.

=cut

=head2 $self->_report_single_test_file_start({test_file => "t/my_test_file.t"})

[This is a method that needs to be over-rided.]

Should start the report for the C<test_file> file.

=cut

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

=head2 $self->_report_final_stats()

[This is a method that needs to be over-rided.]

Reports the final statistics.

=cut

=head2 $self->_fail_other_print_top()

[This is a method that needs to be over-rided.]

Prints the header of the files that failed.

=cut

=head2 $self->_fail_other_report_test($script_name)

[This is a method that needs to be over-rided.]

In case of failure from a different reason - report that test script.
Test::Run iterates over all the scripts and reports them one by one.

=cut


=head2 $self->_fail_other_print_bonus_message()

[This is a method that needs to be over-rided.]

Should report the bonus message in case of failure from a different
reason.

=cut

=head2 $self->_report_tap_event({ 'raw_event' => $event->raw() })

[This is a method that needs to be over-rided.]

=head2 $self->_report_script_start_environment()

[This is a method that needs to be over-rided.]

Should report the environment of the script at its beginning.

=head2 $self->_handle_test_file_opening_error($args)

[This is a method that needs to be over-rided.]

Should handle the case where the test file cannot be opened.

=cut

=head2 $self->_report_test_progress($args)

[This is a method that needs to be over-rided.]

Report the text progress. In the command line it would be a ok $curr/$total
or NOK.

=cut
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

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
