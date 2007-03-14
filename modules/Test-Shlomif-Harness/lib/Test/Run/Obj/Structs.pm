
use strict;
use warnings;

use Test::Run::Base::Struct;
use Carp;

use Test::Run::Obj::FailedObj;
use Test::Run::Obj::TestObj;
use Test::Run::Obj::TotObj;
use Test::Run::Obj::CanonFailedObj;
use Test::Run::Straps::StrapsTotalsObj;


package Test::Run::Straps::StrapsDetailsObj;

use vars qw(@ISA @fields);

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

