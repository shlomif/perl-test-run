package Test::Run::Straps::StrapsTotalsObj_GplArt;

use base 'Test::Run::Base::Struct';

use Test::Run::Assert;

use Test::Run::Straps::StrapsDetailsObj;


sub _def_or_blank {
    return $_[0] if defined $_[0];
    return "";
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

sub _update_todo_event
{
    my ($self) = @_;

    my $event = $self->_event;

    $self->inc_field('todo');
    if ( $event->is_actual_ok() )
    {
        $self->inc_field('bonus');
    }

    return;
}

sub _update_skip_event
{
    my ($self) = @_;

    $self->inc_field('skip');

    return;
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

sub _inc_seen
{
    my $self = shift;

    $self->inc_field('seen');
}

sub _is_event_pass
{
    my $self = shift;

    return 
    (
        $self->_event->is_ok() ||
        $self->_is_event_todo() ||
        $self->_event->has_skip()
    );
}

sub _is_event_todo
{
    my $self = shift;
    
    return $self->_event->has_todo();
}

sub _update_if_pass
{
    my $self = shift;

    if ($self->_is_event_pass())
    {
        $self->inc_field('ok');
    }

    return;
}

sub _update_details
{
    my $self = shift;

    my $event = $self->_event;

    my $details =
        $self->_init_details_obj_instance(
            {
                ok          => $self->_is_event_pass(),
                actual_ok   => _def_or_blank(scalar($event->is_ok())),
                name        => _def_or_blank( $event->description ),
                # $event->directive returns "SKIP" or "TODO" in uppercase
                # and we expect them to be in lowercase.
                type        => lc(_def_or_blank( $event->directive )),
                reason      => _def_or_blank( $event->explanation ),
            },
        );

    assert( defined( $details->ok() ) && defined( $details->actual_ok() ) );
    $self->details()->[$event->number - 1] = $details;

    return;
}

sub _handle_enormous_event_num
{
    my $self = shift;

    return $self->_enormous_num_cb->();
}

sub _update_details_wrapper
{
    my $self = shift;

    if ($self->_is_enormous_event_num())
    {
        $self->_handle_enormous_event_num();
    }
    else
    {
        $self->_update_details();
    }
}

=head2 $self->_handle_event({event => $event, enormous_num_cb => sub {...}});

Updates the state of the details using a new TAP::Parser event - $event .
C<enormous_num_cb> points to a subroutine reference that is the callback for
handling enormous numbers.

=cut

sub handle_event
{
    my ($self, $args) = @_;

    my $event = $args->{event};
    my $callback = $args->{enormous_num_cb};

    $self->_event($event);
    $self->_enormous_num_cb($callback);

    $self->_handle_event_main();
    
    # Cleanup to avoid circular loops, etc.
    $self->_event(undef);
    $self->_enormous_num_cb(undef);
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

