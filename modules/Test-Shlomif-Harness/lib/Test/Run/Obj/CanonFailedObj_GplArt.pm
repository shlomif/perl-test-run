package Test::Run::Obj::CanonFailedObj_GplArt;

=head1 NAME

Test::Run::Obj::CanonFailedObj - an object representing a canon that failed 

=head1 METHODS

=cut

use base 'Test::Run::Base::Struct';

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

