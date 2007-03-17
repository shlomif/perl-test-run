package Test::Run::Straps::StrapsTotalsObj;

=head1 NAME

Test::Run::Straps::StrapsTotalsObj - an object representing the totals of the
straps class.

=head1 FIELDS

=cut

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

use Test::Run::Assert;

use Test::Run::Straps::StrapsDetailsObj;

@fields = (qw(
    bonus
    details
    _enormous_num_cb
    _event
    exit
    filename
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

=head2 $self->bonus()

Number of TODO tests that unexpectedly passed.

=head2 $self->details()

An array containing the details of the individual checks in the test file.

=head2 $self->exit()

The exit code of the test script.

=head2 $self->filename()

The filename of the test script.

=head2 $self->max()

The number of planned tests.

=head2 $self-ok()

The number of tests that passed.

=head2 $self->passing()

A boolean value that indicates whether the entire test script is considered
a success or not.

=head2 $self->seen()

The number of tests that were actually run.

=head2 $self->skip()

The number of skipped tests.

=head2 $self->skip_all()

This field will contain the reason for why the entire test script was skipped,
in cases when it was.

=head2 $self->skip_reason()

The skip reason for the last skipped test that specified such a reason.

=head2 $self->todo()

The number of "Todo" tests that were encountered.

=head2 $self->wait()

The wait code of the test script.

=cut

sub _def_or_blank {
    return $_[0] if defined $_[0];
    return "";
}

=head1 METHODS

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

sub _is_enormous_event_num
{
    my $self = shift;

    return 
    (
        ($self->_event->number > 100_000)
            &&
        ($self->_event->number > ($self->max()||100_000))
    );
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

sub _init_details_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsDetailsObj->new($args);
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

sub _handle_event_main
{
    my $self = shift;

    $self->_inc_seen();
    $self->_update_by_labeled_test_event();
    $self->_update_if_pass();
    $self->_update_details_wrapper();
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

