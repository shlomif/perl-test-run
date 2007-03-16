package Test::Run::Straps::StrapsTotalsObj;

=head1 NAME

Test::Run::Straps::StrapsTotalsObj - an object representing the totals of the
straps class.

=head1 METHODS

=cut

use vars qw(@fields);

use base 'Test::Run::Base::Struct';


@fields = (qw(
    bonus
    details
    exit
    max
    ok
    passing
    seen
    skip
    skip_all
    skip_reason
    todo
    wait
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

=head2 $self->_calc_passing()

Calculates whether the test file has passed.

=cut

sub _calc_passing
{
    my $self = shift;
    return 
    (
        ($self->max() == 0 &&  defined $self->skip_all()) ||
        (
            $self->max() && $self->seen() &&
            $self->max() == $self->seen() &&
            $self->max() == $self->ok()
        )
    );
}

=head2 $self->determine_passing()

Calculates whether the test file has passed and caches it in the passing()
slot.

=cut

sub determine_passing
{
    my $self = shift;
    $self->passing($self->_calc_passing() ? 1 : 0);
}

=head2 $self->update_skip_reason($detail)

Updates the skip reason according to the detail $detail.

=cut

sub update_skip_reason
{
    my $self = shift;
    my $detail = shift;

    if( $detail->type() eq 'skip' )
    {
        my $reason = $detail->reason();
        if (!defined($self->skip_reason()))
        {
            $self->skip_reason($reason);
        }
        elsif ($self->skip_reason() ne $reason)
        {
            $self->skip_reason('various reasons');
        }
    }
}

=head2 $self->last_detail()

Returns the last detail.

=cut

sub last_detail
{
    my $self = shift;
    return $self->details()->[-1];
}

=head2 $self->update_by_labeled_test_event($event)

Update the file totals object $self according to the TAP::Parser event $event.

=cut

sub update_by_labeled_test_event
{
    my ($self, $event) = @_;

    if ($event->has_todo())
    {
        $self->inc_field('todo');
        if ( $event->is_actual_ok() )
        {
            $self->inc_field('bonus');
        }
    }
    elsif ( $event->has_skip ) {
        $self->inc_field('skip');
    }

    return;
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the same terms as Perl 5 itself.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

