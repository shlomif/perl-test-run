package Test::Run::Obj::CanonFailedObj;

use strict;
use warnings;

use base 'Test::Run::Base::Struct';

use vars qw(@fields);

@fields = (qw(
    canon
    failed_num
    result
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

=head2 $self->add_result($result)

Pushes $result to the result() slot.

=cut

sub add_result
{
    my $self = shift;
    push @{$self->result()}, @_;
}

=head2 $self->get_ser_results()

Returns the serialized results.

=cut

sub get_ser_results
{
    my $self = shift;
    return join("", @{$self->result()});
}

=head2 $self->add_Failed($test)

Add a failed test $test to the diagnostics.

=cut

sub _add_Failed_summary
{
    my ($self, $test) = @_;

    $self->add_result(
        sprintf(
            "\tFailed %s/%s tests, ",
            $self->failed_num(),
            $test->max()
        )
    );
}

sub _add_Failed_percent_okay
{
    my ($self, $test) = @_;

    $self->add_result(
        $self->_calc_Failed_percent_okay($test)
    );
}

sub _calc_Failed_percent_okay
{
    my ($self, $test) = @_;

    return
        $test->max() 
            ? sprintf("%.2f%% okay", 100*(1-$self->failed_num()/$test->max()))
            : "?% okay"
        ;
}

sub add_Failed
{
    my ($self, $test) = @_;

    my $max = $test->max();
    my $failed_num = $self->failed_num();

    $self->_add_Failed_summary($test);
    $self->_add_Failed_percent_okay($test);   
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut

sub add_skipped
{
    my ($self, $test) = @_;

    if ($test->skipped())
    {
        $self->_add_actual_skipped($test);
    }
}

sub _add_actual_skipped
{
    my ($self, $test) = @_;

    my $tests_string = (($test->skipped() > 1) ? "tests" : "test");

    $self->add_result(
        sprintf(
            " (less %s skipped %s: %s okay, %s%%)",
            $test->skipped(),
            $tests_string,
            $self->_calc_skipped_percent($test),
        )
    );
}

sub _calc_skipped_percent
{
    my ($self, $test) = @_;

    return 
        $test->max() 
            ? sprintf("%.2f", 100*($test->good()/$test->max()))
            : "?"
        ;
}

sub add_Failed_and_skipped
{
    my ($self, $t) = @_;

    $self->add_Failed($t);
    $self->add_skipped($t);

    return;
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut


=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

1;
