use strict;
use warnings;

use Test::More tests => 4;

package MyTestRun::From;

use base 'Test::Run::Base';

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

__PACKAGE__->delegate_to("_from", [qw(mysum set_g a100)]);

sub test_sum
{
    my $self = shift;

    return $self->mysum(50, 100);
}

package main;


