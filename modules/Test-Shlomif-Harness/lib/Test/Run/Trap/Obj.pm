package Test::Run::Trap::Obj;

use strict;
use warnings;

use base 'Test::Run::Base::Struct';

use Test::More;
use Data::Dumper ();

use Text::Sprintf::Named;
    
use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use Test::Run::Obj;

my @fields = qw(
    die
    exit
    leaveby
    return
    stderr
    stdout
    wantarray
    warn
    run_func
);

sub _get_private_fields
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

sub field_unlike
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $regex, $name) = @_;

    if (! Test::More::unlike($self->$what(), $regex, $name))
    {
        $self->diag_all();
    }
}


sub field_is
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $expected, $name) = @_;

    if (! Test::More::is($self->$what(), $expected, $name))
    {
        $self->diag_all();
    }
}

sub field_is_deeply
{
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $self = shift;
    my ($what, $expected, $name) = @_;

    if (! Test::More::is_deeply($self->$what(), $expected, $name))
    {
        $self->diag_all();
    }
}


sub trap_run
{
    my ($class, $args) = @_;

    my $test_run_class = $args->{class} || "Test::Run::Obj";

    my $test_run_args = $args->{args};

    my $run_func = $args->{run_func} || "runtests";

    my $tester = $test_run_class->new(
        {@{$test_run_args}},
        );

    trap { $tester->$run_func(); };

    return $class->new({ 
        ( map { $_ => $trap->$_() } 
        (qw(stdout stderr die leaveby exit return warn wantarray)))
    });
}

1;

=head1 NAME

Test::Run::Trap::Obj - Utility class for trapping output in testing.

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
