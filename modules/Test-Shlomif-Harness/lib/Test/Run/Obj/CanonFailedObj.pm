package Test::Run::Obj::CanonFailedObj;

use strict;
use warnings;

use base 'Test::Run::Base::Struct';

use vars qw(@fields);

@fields = (qw(
    failed
    _more_results
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub _initialize
{
    my $self = shift;

    $self->NEXT::_initialize(@_);

    $self->_more_results([]);

    return 0;
}

=head2 $self->add_result($result)

Pushes $result to the result() slot.

=cut

sub _get_more_results
{
    my $self = shift;

    return $self->_more_results();
}

sub add_result
{
    my $self = shift;
    push @{$self->_more_results()}, @_;
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
            ? sprintf("%.2f", 100*($self->good($test)/$test->max()))
            : "?"
        ;
}

sub good
{
    my ($self, $test) = @_;

    return $test->max() - $self->failed_num() - $test->skipped();
}

sub add_Failed_and_skipped
{
    my ($self, $t) = @_;

    $self->add_Failed($t);
    $self->add_skipped($t);

    return;
}

sub canon_list
{
    my $self = shift;

    return (@{$self->failed()} == 1) 
        ? [ @{$self->failed()} ]
        : $self->_get_canon_ranges()
        ;
}

sub _get_canon_ranges
{
    my $self = shift;

    my @failed = @{$self->failed()};

    # Assign the first number in the range.
    my $min = shift(@failed);

    my $last = $min;

    my @ranges;

    foreach my $number (@failed, $failed[-1]) # Don't forget the last one
    {
        if (($number > $last+1) || ($number == $last))
        {
            push @ranges, +($min == $last) ? $min : "$min-$last";
            $min = $last = $number;
        }
        else
        {
            $last = $number;
        }
    }

    return \@ranges;
}

sub canon
{
    my $self = shift;

    return join(' ', @{$self->canon_list()});
}


sub _get_failed_string
{
    my $self = shift;

    my $canon = $self->canon_list;

    return 
        sprintf("FAILED %s %s",
            $self->_list_pluralize("test", $canon),
            join(", ", @$canon)
        );
}

sub _get_failed_string_line
{
    my $self = shift;

    return $self->_get_failed_string() . "\n";
}

sub result
{
    my $self = shift;

    return [ $self->_get_failed_string_line(), @{$self->_get_more_results()} ];
}

sub failed_num
{
    my $self = shift;

    return scalar(@{$self->failed()});
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut


=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

1;
