package Test::Run::Core;

use strict;
use warnings;

use base 'Test::Run::Core_GplArt';

use vars qw($VERSION);

use List::MoreUtils ();

use Fatal qw(opendir);

use Time::HiRes ();
use List::Util ();

use Test::Run::Obj::CanonFailedObj;

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
    my $self = shift;

    return $self->accum_array(
        {
            method => "_get_private_simple_params",
        }
    );
}

sub _get_private_simple_params
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

__PACKAGE__->mk_accessors(qw(
    _bonusmsg
    dir_files
    failed_tests
    format_columns
    last_test_elapsed
    last_test_obj
    last_test_results
    list_len
    max_namelen
    output
    _start_time
    Strap
    tot
    width
    ));


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

    return Test::Run::Straps->new({});
}

sub _initialize
{
    my ($self, $args) = @_;

    $self->NEXT::_initialize($args);

    $self->Columns(80);
    $self->Switches("-w");
    $self->_init_simple_params($args);
    $self->dir_files([]);
    $self->Strap(
        $self->_get_new_strap($args),
    );

    return 0;
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

sub _glob_dir
{
    my ($self, $dirname) = @_;

    my $dir;
    opendir $dir, $dirname;
    my @contents = readdir($dir);
    closedir($dir);

    return \@contents;
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

sub _tot_add
{
    my ($self, $field, $diff) = @_;

    $self->tot()->add($field, $diff);
}

sub _tot_inc
{
    my ($self, $field) = @_;

    $self->tot()->inc($field);
}

sub _tot_add_results
{
    my ($self, $results) = @_;

    return $self->tot->add_results($results);
}

sub _create_failed_obj_instance
{
    my $self = shift;
    my $args = shift;
    return Test::Run::Obj::FailedObj->new(
        $args
    );
}

sub _create_test_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Obj::TestObj->new($args);
}

sub _is_failed_and_max
{
    my $self = shift;

    return $self->last_test_obj->is_failed_and_max();
}

sub _tap_event_strap_callback
{
    my ($self, $args) = @_;

    $self->_report_tap_event($args);

    return $self->_tap_event_handle_strap($args);
}

sub _tap_event__calc_conds_raw
{
    my $self = shift;

    return
    [
        [ plan => "header" ],
        [ bailout => "bailout" ],
        [ test => "test" ],
    ];
}

sub _tap_event__calc_conds
{
    my $self = shift;

    return
    [
        map
        {
            my $c = $_;
            my $cond = "is_$c->[0]";
            my $handler = "_strap_$c->[1]_handler";
            +{ cond => $cond, handler => $handler, };
        }
        @{$self->_tap_event__calc_conds_raw()}
    ];
}

sub _tap_event_handle_strap
{
    my ($self, $args) = @_;
    my $event = $args->{event};

    foreach my $c (@{$self->_tap_event__calc_conds()})
    {
        my $cond = $c->{cond};
        my $handler = $c->{handler};

        if ($event->$cond())
        {
            return $self->$handler($args);
        }
    }
    return;
}

=begin _private

=over 4

=item B<_all_ok>

    my $ok = $self->_all_ok();

Tells you if the current test run is OK or not.

=cut

sub _all_ok
{
    my $self = shift;
    return $self->tot->all_ok();
}

=back

=cut

sub _get_dir_files
{
    my $self = shift;

    return $self->_glob_dir($self->Leaked_Dir());
}

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

sub _inc_bad
{
    my $self = shift;

    $self->_tot_inc('bad');

    return;
}

sub _ser_failed_results
{
    my $self = shift;

    return $self->_canonfailed()->get_ser_results();
}

sub _get_current_time
{
    my $self = shift;

    return Time::HiRes::time();
}

sub _set_start_time
{
    my $self = shift;

    if ($self->Timer())
    {
        $self->_start_time($self->_get_current_time());
    }
}

sub _get_dont_know_which_tests_failed_msg
{
    my $self = shift;

    return $self->last_test_obj->_get_dont_know_which_tests_failed_msg();
}

sub _get_elapsed
{
    my $self = shift;

    if ($self->Timer())
    {
        return sprintf(" %8.3fs",
            $self->_get_current_time() - $self->_start_time()
        );
    }
    else
    {
        return "";
    }
}

sub _set_last_test_elapsed
{
    my $self = shift;

    $self->last_test_elapsed($self->_get_elapsed());
}

sub _get_copied_strap_fields
{
    return [qw(Debug Test_Interpreter Switches Switches_Env)];
}

sub _init_strap
{
    my ($self, $args) = @_;

    $self->Strap()->copy_from($self, $self->_get_copied_strap_fields());
}

sub _get_sub_percent_msg
{
    my $self = shift;

    return $self->tot->get_sub_percent_msg();
}

sub _process_all_skipped_test
{
    my $self = shift;

    $self->_report_all_skipped_test();
    $self->_tot_inc('skipped');

    return;
}

sub _fail_other_get_script_names
{
    my $self = shift;

    return [ sort { $a cmp $b } (keys(%{$self->failed_tests()})) ];
}

sub _fail_other_print_all_tests
{
    my $self = shift;

    for my $script (@{$self->_fail_other_get_script_names()})
    {
        $self->_fail_other_report_test($script);
    }
}

sub _fail_other_throw_exception
{
    my $self = shift;

    die Test::Run::Obj::Error::TestsFail::Other->new(
        {text => $self->_get_fail_other_exception_text(),},
    );
}

sub _process_skipped_test
{
    my ($self) = @_;

    return $self->_report_skipped_test();
}


sub _process_all_ok_test
{
    my ($self) = @_;
    return $self->_report_all_ok_test();
}

sub _time_single_test
{
    my ($self, $args) = @_;

    $self->_set_start_time($args);

    $self->_init_strap($args);

    $self->Strap->callback(sub { return $self->_strap_callback(@_); });

    # We trap exceptions so we can nullify the callback to avoid memory
    # leaks.
    my $results;
    eval
    {
        if (! ($results = $self->Strap()->analyze_file($args->{test_file})))
        {
            do
            {
                warn $self->Strap()->error(), "\n";
                next;
            }
        }
    };

    # To avoid circular references
    $self->Strap->callback(undef);

    if ($@ ne "")
    {
        die $@;
    }
    $self->_set_last_test_elapsed($args);

    $self->last_test_results($results);

    return;
}

sub _fail_no_tests_output
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoOutput->new(
        {text => $self->_get_fail_no_tests_output_text(),},
    );
}

sub _failed_canon
{
    my $self = shift;

    return $self->_canonfailed()->canon();
}

sub _get_failed_and_max_msg
{
    my $self = shift;

    return $self->last_test_obj->ml()
        .  $self->_ser_failed_results();
}

sub _canonfailed
{
    my $self = shift;

    my $canon_obj = $self->_canonfailed_get_canon();

    $canon_obj->add_Failed_and_skipped($self->last_test_obj);

    return $canon_obj;
    # Originally returning get_ser_results, canon
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

=head2 $self->_calc_test_struct_ml($results)

Calculates the ml(). (See L<Test::Run::Output>) for the test. 

=cut

sub _calc_test_struct_ml
{
    my $self = shift;

    return "";
}

sub _calc_last_test_obj_params
{
    my $self = shift;

    my $results = $self->last_test_results;
    
    return 
    [
        (
            map { $_ => $results->$_(), } 
            (qw(bonus max ok skip_reason skip_all))
        ),
        skipped => $results->skip(),
        'next' => $self->Strap->next(),
        failed => $results->_get_failed_details(),
        ml => $self->_calc_test_struct_ml($results),
    ];
}

sub _get_fail_no_tests_run_text
{
    return "FAILED--no tests were run for some reason.\n"
}

sub _get_fail_no_tests_output_text
{
    my $self = shift;

    return $self->tot->_get_fail_no_tests_output_text();
}

sub _get_success_msg
{
    my $self = shift;
    return "All tests successful" . $self->_get_bonusmsg() . ".";
}

sub _fail_no_tests_run
{
    my $self = shift;
    die Test::Run::Obj::Error::TestsFail::NoTestsRun->new(
        {text => $self->_get_fail_no_tests_run_text(),},
    );
}

sub _calc_test_struct
{
    my $self = shift;

    my $results = $self->last_test_results;

    $self->_tot_add_results($results);
    
    return $self->last_test_obj(
        $self->_create_test_obj_instance(
            {
                @{$self->_calc_last_test_obj_params()},
            }
        )
    );
}

sub _get_failed_list
{
    my $self = shift;

    return $self->last_test_obj->failed;
}

sub _get_premature_test_dubious_summary
{
    my $self = shift;

    $self->last_test_obj->add_next_to_failed();

    $self->_report_premature_test_dubious_summary();

    return +{ @{$self->_get_failed_and_max_params()} };
}

sub _failed_before_any_test_output
{
    my $self = shift;

    $self->_report_failed_before_any_test_output();

    $self->_inc_bad();

    return $self->_calc_failed_before_any_test_obj();
}

sub _max_len
{
    my ($self, $array_ref) = @_;

    return List::Util::max(map { length($_) } @$array_ref);
}

# TODO : Add _leader_width here.


sub _get_fn_fn
{
    my ($self, $fn) = @_;

    return $fn;
}

sub _get_fn_ext
{
    my ($self, $fn) = @_;

    return (($fn =~ /\.(\w+)\z/) ? $1 : "");
}

sub _get_filename_map_max_len
{
    my ($self, $cb) = @_;

    return $self->_max_len(
        [ map { $self->$cb($_) } @{$self->test_files()} ]
    );
}

sub _get_max_ext_len
{
    my $self = shift;

    return $self->_get_filename_map_max_len("_get_fn_ext");
}

sub _get_max_filename_len
{
    my $self = shift;

    return $self->_get_filename_map_max_len("_get_fn_fn");
}

=head2 $self->_leader_width()

Calculates how long the leader should be based on the length of the
maximal test filename.

=cut

sub _leader_width
{
    my $self = shift;

    return $self->_get_max_filename_len() + 3 - $self->_get_max_ext_len();
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
}

sub _calc_failed_before_any_test_obj
{
    my $self = shift;

    return $self->_create_failed_obj_instance(
        {
            (map { $_ => "??", } qw(canon max failed)),
            (map { $_ => "", } qw(estat wstat)),
            percent => undef,
            name => $self->_get_last_test_filename(),
        },
    );
}

sub _show_results
{
    my($self) = @_;

    $self->_show_success_or_failure();

    $self->_report_final_stats();
}

sub _is_last_test_seen
{
    return shift->last_test_results->seen;
}

sub _get_failed_and_max_params
{
    my $self = shift;

    my $last_test = $self->last_test_obj;

    return
    [
        canon => $self->_failed_canon(),
        failed => $last_test->num_failed(),
        percent => $last_test->calc_percent(),
    ];
}

# The test program exited with a bad exit status.
sub _dubious_return
{
    my $self = shift;

    $self->_report_dubious();

    $self->_inc_bad();

    return $self->_calc_dubious_return_ret_value();
}

sub _get_fail_test_scripts_string
{
    my $self = shift;

    return $self->tot->fail_test_scripts_string();
}

sub _get_undef_tests_params
{
    my $self = shift;

    return
    [
        canon => "??",
        failed => "??",
        percent => undef,
    ];
}

sub _get_fail_tests_good_percent_string
{
    my $self = shift;

    return $self->tot->fail_tests_good_percent_string();
}

sub _get_FWRS_tests_existence_params
{
    my ($self) = @_;

    return
        [
            $self->_is_failed_and_max()
            ? (@{$self->_get_failed_and_max_params()})
            : (@{$self->_get_undef_tests_params()})
        ]
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

sub _is_no_tests_run
{
    my $self = shift;

    return (! $self->tot->tests());
}

sub _is_no_tests_output
{
    my $self = shift;

    return (! $self->tot->max());
}

sub _show_success_or_failure
{
    my $self = shift;

    if ($self->_all_ok())
    {
        return $self->_report_success();
    }
    elsif ($self->_is_no_tests_run())
    {
        return $self->_fail_no_tests_run();
    }
    elsif ($self->_is_no_tests_output())
    {
        return $self->_fail_no_tests_output();
    }
    else
    {
        return $self->_fail_other();
    }
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

sub _get_canonfailed_params
{
    my $self = shift;

    return [failed => $self->_canonfailed_get_failed(),];
}

sub _create_canonfailed_obj_instance
{
    my ($self, $args) = @_;

    return Test::Run::Obj::CanonFailedObj->new($args);
}

sub _canonfailed_get_canon
{
    my ($self) = @_;

    return $self->_create_canonfailed_obj_instance(
        {
            @{$self->_get_canonfailed_params()},
        }
    );
}

sub _calc__run_single_test__callbacks
{
    my $self = shift;

    return [qw(
        _prepare_for_single_test_run
        _time_single_test
        _calc_test_struct
        _process_test_file_results
        _recheck_dir_files    
    )];
}

sub _run_single_test
{
    my ($self, $args) = @_;

    foreach my $cb (@{$self->_calc__run_single_test__callbacks()})
    {
        $self->$cb($args);
    }

    return;
}

sub runtests
{
    my $self = shift;

    local ($\, $,);

    my $ok = eval { $self->_real_runtests(@_) };

    my $error = $@;

    if ($error)
    {
        return $self->_handle_runtests_error(
            {
                ok => $ok,
                error => $error,
            }
        );
    }
    else
    {
        return $ok;
    }
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

=head2 $self->_report_tap_event($args)

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
