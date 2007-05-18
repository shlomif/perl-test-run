package Test::Run::Obj::TotObj;

=head1 NAME

Test::Run::Obj::TotObj - totals encountered for the entire Test::Run session

=head1 DESCRIPTION

Inherits from L<Test::Run::Base::Struct>.

=head1 METHODS

=cut

use vars qw(@fields @counter_fields %counter_fields_map);

use Benchmark qw();

use base qw(Test::Run::Base::Struct);

@counter_fields = (qw(
    bad
    bench
    bonus
    files
    good
    max
    ok
    skipped
    sub_skipped
    todo
));

@fields = (@counter_fields, 'tests');

sub _get_private_fields
{
    return [@fields];
}

%counter_fields_map = (map { $_ => 1 } @counter_fields);

__PACKAGE__->mk_accessors(@fields);

sub _pre_init
{
    my $self = shift;
    foreach my $f (@counter_fields)
    {
        $self->set($f, 0);
    }
    return 0;
}

=head2 $self->add($field, $diff)

Adds the difference $diff to the slot $field, assuming it is a counter field.

=cut

sub add
{
    my ($self, $field, $diff) = @_;
    if (!exists($counter_fields_map{$field}))
    {
        Carp::confess "Cannot add to field \"$field\"!";
    }
    $self->set($field, $self->get($field) + $diff);
    return $self->get($field);
}

=head2 $self->inc($field)

Increments the field $field by 1.

=cut

sub inc
{
    my ($self, $field) = @_;

    return $self->add($field, 1);
}

=head2 $self->bench_timestr()

Retrieves the timestr() "nop" according to Benchmark.pm of the bench() field.

=cut

sub bench_timestr
{
    my $self = shift;

    return Benchmark::timestr($self->bench(), 'nop');
}

=head2 $self->all_ok()

Returns a boolean value - 0 or 1 if all tests were OK.

=cut

sub all_ok
{
    my $self = shift;

    return $self->_normalize_cond(
           ($self->bad() == 0) 
        && ($self->max() || $self->skipped())
    );
}

sub _normalize_cond
{
    my ($self, $cond) = @_;
    return ($cond ? 1 : 0);
}

sub fail_test_scripts_string
{
    my $self = shift;

    return $self->_get_obj_formatter(
        "%(bad)s/%(tests)s test scripts",
    )->obj_format($self);
}

=head2 $self->add_results($results)

Adds the sums from a results object.

=cut

sub add_results
{
    my ($self, $results) = @_;

    foreach my $type (qw(bonus max ok todo))
    {
        $self->add($type, $results->$type());
    }

    $self->add("sub_skipped", $results->skip())
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

