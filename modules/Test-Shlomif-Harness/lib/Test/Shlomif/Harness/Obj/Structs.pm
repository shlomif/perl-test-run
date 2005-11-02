
use strict;
use warnings;

use Test::Shlomif::Harness::Base;

package Test::Shlomif::Harness::Obj::FailedObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Shlomif::Harness::Base));

@fields = (qw(
    canon
    estat
    failed
    max
    name
    percent
    wstat
));

%fields_map = (map { $_ => 1 } @fields);

__PACKAGE__->mk_accessors(@fields);

sub _initialize
{
    my $self = shift;
    my (%args) = @_;

    while (my ($k, $v) = each(%args))
    {
        if (exists($fields_map{$k}))
        {
            $self->set($k, $v);
        }
        else
        {
            die "Called with undefined field \"$k\"";
        }
    }
}

1;

package Test::Shlomif::Harness::Obj::TestObj;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Shlomif::Harness::Base));

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

%fields_map = (map { $_ => 1 } @fields);

__PACKAGE__->mk_accessors(@fields);

sub _initialize
{
    my $self = shift;
    my (%args) = @_;

    while (my ($k, $v) = each(%args))
    {
        if (exists($fields_map{$k}))
        {
            $self->set($k, $v);
        }
        else
        {
            die "Called with undefined field \"$k\"";
        }
    }
}

sub add_to_failed
{
    my $self = shift;
    push @{$self->failed()}, @_;
}

1;

package Test::Shlomif::Harness::Obj::TotObj;

use vars qw(@ISA @fields %fields_map @counter_fields %counter_fields_map);

@ISA = (qw(Test::Shlomif::Harness::Base));

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

%fields_map = (map { $_ => 1 } @fields);
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

sub _initialize
{
    my $self = shift;
    my (%args) = @_;

    $self->_pre_init();

    while (my ($k, $v) = each(%args))
    {
        if (exists($fields_map{$k}))
        {
            $self->set($k, $v);
        }
        else
        {
            die "Called with undefined field \"$k\"";
        }
    }
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

