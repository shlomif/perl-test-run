#!/usr/bin/perl

use strict;
use warnings;

BEGIN
{
    use vars qw(@rand_values);
    *CORE::GLOBAL::rand = sub { return shift(@rand_values)+0.5; };
};

use Test::More tests => 2;

use Test::Run::CmdLine::Prove;

use File::Spec;


sub get_test_files
{
    my $args = shift;
    my $prove = Test::Run::CmdLine::Prove->new({'args' => $args});
    return $prove->_get_test_files();
}


@rand_values = (
    # (1,2,3,4,5)
    3, 
    # (1,2,3,5|4)
    0,
    # (5,2,3|1,4)
    1,
    # (5,3|2,1,4)
    1,
    # |5,3,2,1,4)
    0,
);

# TEST
is_deeply (
    get_test_files (["--shuffle", "foo.t", "bar.t", "baz.t", "quux.t", "patro.t"]),
    ["patro.t", "baz.t", "bar.t", "foo.t", "quux.t"],
    # Testing for shuffling.
);

@rand_values = (
    # (1,2,3,4,5)
    3, 
    # (1,2,3,5|4)
    0,
    # (5,2,3|1,4)
    1,
    # (5,3|2,1,4)
    1,
    # |5,3,2,1,4)
    0,
);

# TEST
is_deeply (
    get_test_files (["-s", "foo.t", "bar.t", "baz.t", "quux.t", "patro.t"]),
    ["patro.t", "baz.t", "bar.t", "foo.t", "quux.t"],
    # Testing for shuffling.
);

