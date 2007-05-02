package Test::Run::Trap::Obj;

use strict;
use warnings;

use base 'Test::Run::Base::Struct';

use Test::More;
use Data::Dumper ();

use Text::Sprintf::Named;

my @fields = qw(
    die
    exit
    leaveby
    return
    stderr
    stdout
    wantarray
    warn
);

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub _stringify_value
{
    my ($self, $name) = @_;

    my $value = $self->$name();

    if (($name eq "return") || ($name eq "warn"))
    {
        return Data::Dumper->new([$value])->Dump();
    }
    else
    {
        return (defined($value) ? $value : "");
    }
}

sub diag_all
{
    my $self = shift;

    diag(
        Text::Sprintf::Named->new(
            {
                fmt =>
            join( "",
            map { "$_ ===\n{{{{{{\n%($_)s\n}}}}}}\n\n" }
            (@fields))
            }
        )->format({args => { map { my $name = $_; 
                        ($name => $self->_stringify_value($name)) }
                    @fields
                }})
    );
}

sub field_like
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $regex, $name) = @_;

    if (! Test::More::like($self->$what(), $regex, $name))
    {
        $self->diag_all();
    }
}

1;

