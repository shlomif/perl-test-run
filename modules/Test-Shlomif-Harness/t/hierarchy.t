#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

package A;

# B is-a A.
# Thus we get B after A:
# A B

package B;

our @ISA = (qw(A));

package C;

our @ISA = (qw(B));

package D; 

our @ISA = (qw(B));

package E;

our @ISA = (qw(D C));

package main;

use Test::Run::Class::Hierarchy (qw(hierarchy_of rev_hierarchy_of));

# TEST
is_deeply (hierarchy_of("C"), [qw(C B A)],
    "Checking a simple hierarchy"
);

# TEST
is_deeply (hierarchy_of("E"), [qw(E D C B A)],
    "Checking a multi-inheritance hierarchy"
);


# TEST
is_deeply (rev_hierarchy_of("C"), [qw(A B C )],
    "Checking a simple hierarchy"
);

# TEST
is_deeply (rev_hierarchy_of("E"), [qw(A B C D E)],
    "Checking a multi-inheritance hierarchy"
);
