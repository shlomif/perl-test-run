
use strict;
use warnings;

use Test::Run::Base;

package Test::Run::Obj::FailedObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

@fields = (qw(
    canon
    estat
    failed
    max
    name
    percent
    wstat
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

1;

package Test::Run::Obj::TestObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

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

sub add_to_failed
{
    my $self = shift;
    push @{$self->failed()}, @_;
}

1;

package Test::Run::Obj::TotObj;

use vars qw(@ISA @fields %fields_map @counter_fields %counter_fields_map);

@ISA = (qw(Test::Run::Base::Struct));

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

sub _get_fields
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

sub add
{
    my ($self, $field, $diff) = @_;
    if (!exists($counter_fields_map{$field}))
    {
        die "Cannot add to field \"$field\"!";
    }
    $self->set($field, $self->get($field) + $diff);
    return $self->get($field);
}

1;

package Test::Run::Obj::CanonFailedObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

@fields = (qw(
    canon
    result
    failed_num
));

sub _get_fields
{
    return [@fields];
}

sub add_result
{
    my $self = shift;
    push @{$self->result()}, @_;
}

sub get_ser_results
{
    my $self = shift;
    return join("", @{$self->result()});
}

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

__PACKAGE__->mk_accessors(@fields);

1;

package Test::Run::Straps::StrapsTotalsObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

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

sub determine_passing
{
    my $self = shift;
    $self->passing($self->_calc_passing() ? 1 : 0);
}

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

1;

package Test::Run::Straps::StrapsDetailsObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

@fields = (qw(
    actual_ok
    diagnostics
    name
    ok
    reason
    type
));

sub _get_fields
{
    return [@fields];
}

sub _pre_init
{
    my $self = shift;
    $self->diagnostics("");
}
__PACKAGE__->mk_accessors(@fields);

sub append_to_diag
{
    my ($self, $text) = @_;
    $self->diagnostics($self->diagnostics().$text);
}

1;

