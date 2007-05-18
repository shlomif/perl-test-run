#!/usr/bin/perl

# Generator for a makefile that can be used to test and install a sequence
# of Perl CPAN-like distributions
#
# Written by Shlomi Fish
# License: MIT X11 ( http://www.opensource.org/licenses/mit-license.php )

use strict;
use warnings;

use Getopt::Long;

my $o_fn = "-";
my $prefix = "/usr";
my @dirs;

GetOptions (
    "o=s" => \$o_fn,
    "prefix=s" => \$prefix,
    "dir=s\@" => \@dirs,
);

my $text = "";

sub process_dir
{
    my $dir = shift;
    if (-e "$dir/Build.PL")
    {
        process_mb_dir($dir);
    }
    elsif (-e "$dir/Makefile.PL")
    {
        process_eumm_dir($dir);
    }
    else
    {
        die "Unknown install method for directory $dir.";
    }
}

sub process_eumm_dir
{
    my $dir = shift;
    my $bin_prefix = q{\\$$(SITEPREFIX)/bin};
    handle_deps($dir, 
        [
            "perl Makefile.PL PREFIX=\"$prefix\" INSTALLSITEBIN=\"$bin_prefix\" INSTALLSITESCRIPT=\"$bin_prefix\"", 
            "make", 
            "make test", 
            "make install",
        ],
        "make clean",
    );
}

sub process_mb_dir
{
    my $dir = shift;
    handle_deps($dir, 
        [
            "perl Build.PL", 
            "./Build", 
            "./Build test", 
            "./Build install prefix=\"$prefix\"",
        ],
        "./Build clean",
    );
}

my $id_num = 1;

sub handle_deps
{
    my ($dir, $deps_ref, $clean_dep) = @_;
    my @deps = reverse(@$deps_ref);
    my $id = "target" . ($id_num++);
    $text .= "${dir}: $id-step0\n\n";
    foreach my $i (0 .. $#deps)
    {
        $text .= "$id-step${i}: " . 
            (($i == $#deps) ? "" : ("$id-step" . ($i+1))) . 
            "\n";
        $text .= "\t(cd $dir && " . $deps[$i] . ")\n";
        $text .= "\n";
    }
    $text .= "CLEAN--${dir}:\n";
    $text .= "\t(cd $dir && $clean_dep)\n";
    $text .= "\n";
}

foreach my $d (@dirs)
{
    process_dir($d);
}

if ($o_fn eq "-")
{
    open O, ">&STDOUT";
}
else
{
    open O, ">", $o_fn;
}

print O "all: ", join(" ", @dirs) . "\n\n";

print O "cleanall: ", join(" ", map {"CLEAN--$_"} @dirs). "\n\n";

print O $text;

close(O);

