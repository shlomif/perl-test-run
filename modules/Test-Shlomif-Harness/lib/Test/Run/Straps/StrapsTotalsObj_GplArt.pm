package Test::Run::Straps::StrapsTotalsObj_GplArt;

use base 'Test::Run::Base::Struct';

use Test::Run::Straps::StrapsDetailsObj;

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

sub _update_by_labeled_test_event
{
    my $self = shift;

    my $event = $self->_event;

    if ($event->has_todo())
    {
        $self->_update_todo_event();
    }
    elsif ($event->has_skip())
    {
        $self->_update_skip_event();
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

