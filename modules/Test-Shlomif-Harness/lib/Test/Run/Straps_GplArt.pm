# -*- Mode: cperl; cperl-indent-level: 4 -*-
package Test::Run::Straps_GplArt;

use strict;
use warnings;

use Test::Run::Base;

use base 'Test::Run::Straps::Base';

=head1 NAME

Test::Run::Straps - detailed analysis of test results

=head1 SYNOPSIS

  use Test::Run::Straps;

  my $strap = Test::Run::Straps->new;

  # Various ways to interpret a test
  my $results = $strap->analyze($name, \@test_output);
  my $results = $strap->analyze_fh($name, $test_filehandle);
  my $results = $strap->analyze_file($test_file);

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

=head1 ANALYSIS

=cut



sub _handle_enormous_event_num
{
    my $self = shift;

    if ( !$self->too_many_tests() )
    {
        warn "Enormous test number seen [test ", $self->_event->number, "]\n";
        warn "Can't detailize, too big.\n";
        $self->too_many_tests(1);
    }
}


=head2 $strap->analyze_file( $test_file )

    my %results = $strap->analyze_file($test_file);

Like C<analyze>, but it runs the given C<$test_file> and parses its
results.  It will also use that name for the total report.

=cut

sub _get_analysis_file_handle
{
    my($self) = @_;

    my $file = $self->file();

    unless( -e $file ) {
        $self->error("$file does not exist");
        return;
    }

    unless( -r $file ) {
        $self->error("$file is not readable");
        return;
    }

    local $ENV{PERL5LIB} = $self->_INC2PERL5LIB;
    $self->_invoke_cb({'type' => "report_start_env"});

    # *sigh* this breaks under taint, but open -| is unportable.
    my $line = $self->_command_line($file);

    my $file_handle;
    unless ( open($file_handle, "$line|" )) {
        $self->_invoke_cb(
            {
                type => "could_not_run_script",
                cmd_line => $line,
                file => $file,
                error => $!,
            }
        );
        return;
    }

    $self->_restore_PERL5LIB();

    return $self->_file_handle($file_handle);
}

sub _cleanup_analysis
{
    my ($self) = @_;

    my $results = $self->results();

    close ($self->_file_handle());
    $self->_file_handle(undef);

    if ($self->exception() ne "")
    {
        die $self->exception();
    }

    $results->wait($?);
    if( $? && $self->_is_vms() ) {
        eval q{use vmsish "status"; $results->exit($?)};
    }
    else {
        $results->exit($self->_wait2exit($?));
    }
    $results->passing(0) unless $? == 0;

    return;
}

sub analyze_file
{
    my ($self, $file) = @_;

    # Assign it here so it won't be passed around.
    $self->file($file);

    $self->_get_analysis_file_handle()
        or return;

    $self->_analyze_fh_wrapper();

    $self->_cleanup_analysis();

    return $self->results();
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

sub _get_shebang
{
    my($self, $file) = @_;

    my $test_fh;
    if (!open($test_fh, $file))
    {
        $self->_handle_test_file_opening_error(
            {
                file => $file,
                error => $!,
            }
        );
        return "";
    }
    my $shebang = <$test_fh>;
    if (!close($test_fh))
    {
        $self->_handle_test_file_closing_error(
            {
                file => $file,
                error => $!,
            }
        );
    }
    return $shebang;
}

=head2 $strap->_switches( $file )

Formats and returns the switches necessary to run the test.

=cut

sub _switches {
    my($self, $file) = @_;

    # my @existing_switches = $self->_cleaned_switches( $Test::Run::Obj::Switches, $ENV{HARNESS_PERL_SWITCHES} );
    my @existing_switches = @{$self->_cleaned_switches( [$self->Switches(), $self->Switches_Env()] )};
    my @derived_switches;

    my $shebang = $self->_get_shebang($file);

    my $taint = ( $shebang =~ /^#!.*\bperl.*\s-\w*([Tt]+)/ );
    push( @derived_switches, "-$1" ) if $taint;

    # When taint mode is on, PERL5LIB is ignored.  So we need to put
    # all that on the command line as -Is.
    # MacPerl's putenv is broken, so it will not see PERL5LIB, tainted or not.
    if ( $taint || $self->_is_macos() ) {
        my @inc = @{$self->_filtered_INC};
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

=head1 Parsing

Methods for identifying what sort of line you're looking at.

=cut

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

=head1 LICENSE

This file is distributed under the same terms as perl. (GPL2 or Later +
Artistic 1).

=head1 SEE ALSO

L<Test::Run>

=cut


1;
