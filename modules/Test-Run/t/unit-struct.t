#!/usr/bin/perl

use strict;
use warnings;

# use lib "./t/lib";

use Test::More tests => 6;

package MyClass;

use Moose;

extends ('Test::Run::Base::Struct');

sub _get_private_fields
{
    return [qw(field1 field2)];
}

has 'field1' => (is => "rw", isa => "Str");
has 'field2' => (is => "rw", isa => "Str");

package main;

{
    my $class =
        MyClass->new(
            {
                field1 => "Value 1",
                field2 => "val2",
            }
        );

    # TEST
    ok ($class, "Object was instantiated");

    # TEST
    is ($class->field1(), "Value 1", "field1()'s value is OK.");

    # TEST
    is ($class->field2(), "val2", "field2()'s value is OK.");
}

{
    my $self;

    eval {
        $self = MyClass->new(
            {
                'field1' => "MyValue 1",
                'non_existent' => "iSuck",
            }
        );
    };

    my $err = $@;

    # TEST
    like(
        $err,
        qr{\ACalled with undefined field "non_existent"},
        "Initialize a struct with an unknown field.",
    );
}


package MyNumClass;

use Moose;

extends ('Test::Run::Base::Struct');

sub _get_private_fields
{
    return [qw(age name)];
}

has 'age' => (is => "rw", isa => "Num");
has 'name' => (is => "rw", isa => "Str");

package main;

{
    my $jack = MyNumClass->new(
        {
            name => "Jack",
            age => 10,
        }
    );

    $jack->add_to_field('age', 3);

    # TEST
    is ($jack->age(), 13, "Age was incremented");

    eval {
        $jack->add_to_field('non-exist', 3);
    };

    my $err = $@;

    # TEST
    like(
        $err, 
        qr{\ATrying to increment non-existent field "non-exist"},
        "Failed to increment non-existent field.",
    );
}
