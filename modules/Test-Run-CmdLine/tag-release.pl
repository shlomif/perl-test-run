#!/usr/bin/perl

use strict;
use warnings;

use IO::All;

my ($version) = 
    (map { m{\$VERSION *= *'([^']+)'} ? ($1) : () } 
    io->file("./lib/Test/Run/CmdLine.pm")->getlines()
    )
    ;

if (!defined ($version))
{
    die "Version is undefined!";
}

my @cmd = (
    "svn", "copy", "-m",
    "Tagging Test-Run-CmdLine as $version",
    "https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/trunk",
    "https://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/tags/releases/modules/Test-Run-CmdLine/$version",
);

print join(" ", @cmd), "\n";
exec(@cmd);
