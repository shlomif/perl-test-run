package Test::Run::Obj::TestObj;

=head1 NAME

Test::Run::Obj::TestObj - results of a single test script.

=cut

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

@fields = (qw(
    ok
    next
    max
    failed
    bonus
    skipped
    skip_reason
    skip_all
    ml
));

=head1 FIELDS

=head2 $self->bonus()

Number of TODO tests that unexpectedly passed.

=head2 $self->failed()

Returns an array reference containing list of test numbers that failed.

=head2 $self->ok()

Number of tests that passed.

=head2 $self->next()

The next expected event.

=head2 $self->max()

The number of plannedt tests.

=head2 $self->skipped()

The number of skipped tests.

=head2 $self->skip_all()

This field will contain the reason for why the entire test script was skipped,
in cases when it was.

=head2 $self->skip_reason()

The skip reason for the last skipped test that specified such a reason.

=cut

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

=head1 $self->add_to_failed(@failures)

Add failures to the failed() slot.

=cut

sub add_to_failed
{
    my $self = shift;
    push @{$self->failed()}, @_;
}

sub _get_reason_default
{
    return "no reason given";
}

=head2 $self->get_reason()

Gets the reason or defaults to the default.

=cut 

sub get_reason
{
    my $self = shift;

    return
        +(defined($self->skip_all()) && length($self->skip_all())) ?
            $self->skip_all() :
            $self->_get_reason_default()
        ;
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

