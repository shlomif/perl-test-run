
use strict;
use warnings;

use Test::Run::Base;

package Test::Run::Obj::Error;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Base::Struct));

@fields = (qw(
    package
    file
    line
    text
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub initialize
{
    my $self = shift;
    my ($pkg,$file,$line) = caller(1);
    $self->package($pkg);
    $self->file($file);
    $self->line($line);
    return $self->SUPER::initialize(@_);
}

1;

package Test::Run::Obj::Error::TestsFail;

use vars qw(@ISA @fields %fields_map);

@ISA = (qw(Test::Run::Obj::Error));

1;

