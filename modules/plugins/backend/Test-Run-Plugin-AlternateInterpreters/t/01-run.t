#!/usr/bin/perl

use strict;
use warnings;

use File::Spec;

use Test::Run::Obj;
use Test::Run::Plugin::AlternateInterpreters;

package MyTestRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Plugin::AlternateInterpreters Test::Run::Obj));

package main;

use Test::More tests => 1;

{
    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";

    my $tester = MyTestRun->new(
        {
            test_files => 
            [
                "t/sample-tests/success1.cat",
                "t/sample-tests/one-ok.t"
            ],
            alternate_interpreters =>
            [
                {
                    cmd => 
                    ("$^X " . File::Spec->catfile(
                        File::Spec->curdir(), "t", "data", 
                        "interpreters", "cat.pl"
                        ) . " "
                    ),
                    type => "regex",
                    pattern => '\.cat$',
                },
            ],
        }
        );

    $tester->runtests();

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    # TEST
    ok (($text =~ m/All tests successful\./), 
        "All test are successful with multiple interpreters");
}

