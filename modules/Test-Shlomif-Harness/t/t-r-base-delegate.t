use strict;
use warnings;

use Test::More tests => 5;

package MyTestRun::From;

use base 'Test::Run::Base';

sub _initialize
{
    my $self = shift;

    $self->set_g(0);

    return 0;
}

sub a100
{
    return 100;
}

sub set_g
{
    my ($self, $g) = @_;

    $self->{g} = $g;

    return;
}

sub mysum
{
    my ($self, $x, $y) = @_;

    return $x+$y+$self->{g};
}

package MyTestRun::To;

use base 'Test::Run::Base';

__PACKAGE__->mk_accessors(qw(_from));

__PACKAGE__->delegate_methods("_from", [qw(mysum set_g a100)]);

sub _initialize
{
    my $self = shift;

    $self->_from(MyTestRun::From->new());

    return 0;
}

sub test_sum
{
    my $self = shift;

    return $self->mysum(50, 100);
}

package main;

my $obj = MyTestRun::To->new();

# TEST
ok($obj, "Object Construction");

# TEST
is ($obj->a100(), 100, "a100 in the delegated object returns 100");

$obj->set_g(24);
# TEST
is ($obj->mysum(20,80), 124, "mysum returns a right result");

$obj->set_g(100);
# TEST
is ($obj->mysum(2,8), 110, "mysum No. 2");

$obj->set_g(3);
# TEST
is ($obj->test_sum(), 153, "Delegated and non-delegated methods");

