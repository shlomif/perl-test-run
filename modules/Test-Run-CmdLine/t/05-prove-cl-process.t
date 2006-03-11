#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;

use Test::Run::CmdLine::Prove;

use File::Spec;

sub mytest
{
    my $args = shift;
    my $prove = Test::Run::CmdLine::Prove->new('args' => $args);
    return $prove->ext_regex_string();
}

# TEST
is (mytest ([qw{t/hello.t}]), '\.(?:t)$', "Testing for default extension");
# TEST
is (mytest ([qw{--ext=cgi t}]), '\.(?:cgi)$', "Testing for single extension");
# TEST
is (mytest (['--ext=cgi,pl', 't']), '\.(?:cgi|pl)$', 
    "Testing for extensions separated with commas");
# TEST
is (mytest (['--ext=cgi,.pl', '--ext=.hello,perl', 't']), 
    '\.(?:cgi|pl|hello|perl)$',
    "Testing for several extension args along with periods"
);

sub get_test_files
{
    my $args = shift;
    my $prove = Test::Run::CmdLine::Prove->new('args' => $args);
    return $prove->_get_test_files();
}

my $sample_tests_dir = File::Spec->catfile("t", "sample-tests");
my $test_file = File::Spec->catfile($sample_tests_dir, "one-ok.t");
my $with_myhello_file = File::Spec->catfile($sample_tests_dir, "with-myhello");
my $test_dir1 = File::Spec->catdir($sample_tests_dir, "test-dir1");
my $ext_test_dir = File::Spec->catdir($sample_tests_dir, "ext-test-dir");
my $recurse_dir = File::Spec->catdir($sample_tests_dir, "recurse-dir");

# TEST
is_deeply (
    get_test_files ([$test_file]), 
    [$test_file],
    "Testing one file"
);

# TEST
is_deeply (
    get_test_files ([$test_file, $with_myhello_file]), 
    [$test_file, $with_myhello_file],
    "Testing two files (one without a proper extension)"
);

# TEST
is_deeply (
    get_test_files ([$test_dir1]),
    [
        File::Spec->catfile($test_dir1, "mytest.t"),
        File::Spec->catfile($test_dir1, "test1.t"),
        File::Spec->catfile($test_dir1, "test2.t"),
    ],
    "Testing Directory (non recursive)",
);

# TEST
is_deeply (
    get_test_files (["--ext=pl,my", $ext_test_dir]),
    [
        File::Spec->catfile($ext_test_dir, "bar.my"),
        File::Spec->catfile($ext_test_dir, "foo.my"),
        File::Spec->catfile($ext_test_dir, "hello.pl"),
        File::Spec->catfile($ext_test_dir, "myfile.pl"),
    ],
    "Testing directory with extensions (non recursive)",
);

# TEST
is_deeply (
    get_test_files (["--recurse", $recurse_dir]),
    [
        map { File::Spec->catfile($recurse_dir, split(/\//, $_)) }
        (qw(
            a.t
            b.t
            c/a.t
            c/b/h.t
            c/y.t
            e.t
            i/r.t
            i/sa.t
            i/sb.t
            z.t
        ))
    ],
    "Testing recursive directory",
);

# TEST
is_deeply (
    get_test_files (["-r", $recurse_dir]),
    [
        map { File::Spec->catfile($recurse_dir, split(/\//, $_)) }
        (qw(
            a.t
            b.t
            c/a.t
            c/b/h.t
            c/y.t
            e.t
            i/r.t
            i/sa.t
            i/sb.t
            z.t
        ))
    ],
    "Testing recursive directory",
);

