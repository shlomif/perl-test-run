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

