package Test::Run::Base;

use strict;
use warnings;

use Class::Accessor;

use vars (qw(@ISA));

@ISA = (qw(Class::Accessor));

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

=head2 $dest->copy_from($source, [@fields])

Assigns the fields C<@fields> using their accessors based on their values
in C<$source>.

=cut

sub copy_from
{
    my ($dest, $source, $fields) = @_;

    foreach my $f (@$fields)
    {
        $dest->$f($source->$f());
    }

    return;
}

1;
