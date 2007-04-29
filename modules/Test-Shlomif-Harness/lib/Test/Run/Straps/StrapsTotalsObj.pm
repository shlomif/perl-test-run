package Test::Run::Straps::StrapsTotalsObj;

use strict;
use warnings;

=head1 NAME

Test::Run::Straps::StrapsTotalsObj - an object representing the totals of the
straps class.

=head1 FIELDS

=cut

use base 'Test::Run::Straps::StrapsTotalsObj_GplArt';

use vars qw(@fields);

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

=head1 METHODS

=head2 $self->_calc_passing()

Calculates whether the test file has passed.

=cut

sub _is_skip_all
{
    my $self = shift;
    
    return (($self->max() == 0) && defined($self->skip_all()));
}

sub _is_all_tests_passed
{
    my $self = shift;

    return
    (
        $self->max && $self->seen
        && ($self->max == $self->seen)
        && ($self->max == $self->ok)
    );
}

sub _calc_passing
{
    my $self = shift;

    return ($self->_is_skip_all() || $self->_is_all_tests_passed());
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

=head2 $self->last_detail()

Returns the last detail.

=cut

sub last_detail
{
    my $self = shift;

    return $self->details->[-1];
}

sub _calc_enormous_event_num
{
    my $self = shift;

    return 100_000;
}

sub _is_enormous_event_num
{
    my $self = shift;

    my $large_num = $self->_calc_enormous_event_num();

    return
        +($self->_event->number > $large_num)
            &&
         ($self->_event->number > ($self->max || $large_num))
        ;
}

sub _init_details_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsDetailsObj->new($args);
}

sub _handle_event_main
{
    my $self = shift;

    $self->_inc_seen();
    $self->_update_by_labeled_test_event();
    $self->_update_if_pass();
    $self->_update_details_wrapper();
}

sub _def_or_blank
{
    my $value = shift;

    return defined($value) ? $value : "";
}

sub _defined_hash_values
{
    my ($self, $hash) = @_;

    return
    {
        map 
        { $_ => _def_or_blank($hash->{$_}) }
        keys(%$hash)
    };
}

sub _calc_always_def_details_initializer
{
    my $self = shift;

    my $event = $self->_event;

    return 
    {
        actual_ok => scalar($event->is_ok()),
        name => $event->description,
        type => lc($event->directive),
        reason => $event->explanation,
    };
}

sub _calc_defined_details
{
    my $self = shift;

    $self->_defined_hash_values(
        $self->_calc_always_def_details_initializer()
    );
}

sub _calc_details
{
    my $self = shift;

    my $event = $self->_event;

    return
        $self->_init_details_obj_instance(
            {
                ok => $self->_is_event_pass(),
                %{$self->_calc_defined_details()},
            }
        );
}

sub _update_details
{
    my ($self) = @_;

    $self->details->[$self->_event->number - 1] = $self->_calc_details();

    return ;
}

sub _update_skip_event
{
    my $self = shift;

    $self->inc_field('skip');

    return;
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

sub _handle_enormous_event_num
{
    my $self = shift;

    return $self->_enormous_num_cb->();
}

sub _update_todo_event
{
    my $self = shift;

    $self->inc_field('todo');

    if ($self->_event->is_actual_ok())
    {
        $self->inc_field('bonus');
    }

    return;
}


sub _inc_seen
{
    my $self = shift;

    $self->inc_field('seen');
}

=head2 $self->_handle_event({event => $event, enormous_num_cb => sub {...}});

Updates the state of the details using a new TAP::Parser event - $event .
C<enormous_num_cb> points to a subroutine reference that is the callback for
handling enormous numbers.

=cut

sub _setup_event
{
	my ($self, $args) = @_;

	$self->_event($args->{event});
    $self->_enormous_num_cb($args->{enormous_num_cb});

	return ;
}

sub _detach_event
{
    my ($self) = @_;

	$self->_event(undef);
    $self->_enormous_num_cb(undef);
}

sub handle_event
{
    my ($self, $args) = @_;

    $self->_setup_event($args);

    $self->_handle_event_main();

    $self->_detach_event();
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

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

1;

