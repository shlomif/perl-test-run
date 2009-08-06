#!/usr/bin/perl 

use strict;
use warnings;

use Cwd;
use File::Spec;

my $inst_modules_dir = "$ENV{HOME}/apps/perl/modules";


my $cwd = Cwd::getcwd();

my ($volume, $directories) = File::Spec->splitpath( $cwd, 1);

# Get to the checkout root.
my @source_dir = File::Spec->splitdir($cwd);
for my $components_to_remove (1 .. 2)
{
    pop(@source_dir);
}

my $modules_dir = File::Spec->catfile(@source_dir, "modules");
system($^X,"gen-perl-modules-inst-makefile.pl", 
    "-o", File::Spec->catfile($cwd, "Modules.mak"),
    "--prefix=$inst_modules_dir",
    (map { "--dir=" . 
            File::Spec->catdir($modules_dir, split(m{/}, $_)) 
         } 
    (qw(
         Test-Run
         Test-Run-CmdLine
         Test-Run-Plugin-ColorSummary
         Test-Run-Plugin-FailSummaryComponents
         Test-Run-Plugin-AlternateInterpreters
         Test-Run-Plugin-CollectStats
         Test-Run-Plugin-ColorFileVerdicts
         Test-Run-Plugin-TrimDisplayedFilenames
    ))
)
);

