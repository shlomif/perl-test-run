package Test::Run::Obj::CanonFailedObj;

=head1 NAME

Test::Run::Obj::CanonFailedObj - an object representing a canon that failed 

=head1 METHODS

=cut

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

@fields = (qw(
    canon
    result
    failed_num
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

sub add_Failed
{
    my ($self, $test) = @_;

    my $max = $test->max();
    my $failed_num = $self->failed_num();

    $self->add_result("\tFailed $failed_num/$max tests, ");
    $self->add_result(
        $max ?
            (sprintf("%.2f",100*(1-$failed_num/$max)),"% okay") :
            "?% okay"
        );
}

=head2 $self->add_skipped($test)

Add a skipped test.

=cut

sub add_skipped
{
    my ($self, $test) = @_;

    my $skipped = $test->skipped();
    my $max = $test->max();

    if ($skipped) {
        my $good = $max - $self->failed_num() - $skipped;
        my $ender = ($skipped > 1) ? "s" : "";
        $self->add_result(
            " (less $skipped skipped test$ender: $good okay, " .
            ($max ? sprintf("%.2f%%)",100*($good/$max)) : "?%)")
        );
    }
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the same terms as Perl itself.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

