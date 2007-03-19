#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

use Term::ANSIColor;
use Config;
use File::Spec;
use Cwd;

my $blib = File::Spec->catfile( File::Spec->curdir, "blib" );
my $lib = File::Spec->catfile( $blib, "lib" );
my $abs_lib = Cwd::abs_path($lib);

sub mydiag
{
    diag( "\$trap->stdout() is\n". $trap->stdout() 
        . "\$trap->stderr() is\n". $trap->stderr());
}

{
    local %ENV = %ENV;
    
    $ENV{'PERL5LIB'} = $abs_lib.$Config{'path_sep'}.$ENV{'PERL5LIB'};
    delete($ENV{'HARNESS_FILELEAK_IN_DIR'});
    delete($ENV{'HARNESS_VERBOSE'});
    delete($ENV{'HARNESS_DEBUG'});
    delete($ENV{'HARNESS_COLUMNS'});
    delete($ENV{'HARNESS_TIMER'});
    delete($ENV{'HARNESS_NOTTY'});
    delete($ENV{'HARNESS_PERL'});
    delete($ENV{'HARNESS_PERL_SWITCHES'});
    delete($ENV{'HARNESS_DRIVER'});
    delete($ENV{'HARNESS_PLUGINS'});
    delete($ENV{'PROVE_SWITCHES'});
    delete($ENV{'PERL_HARNESS_VERDICT_COLORS'});

    $ENV{'HARNESS_PLUGINS'} = "ColorFileVerdicts";
    
    {
        trap {
            system("runprove", 
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            );
        };

        my $color = color("green");
        my $reset = color("reset");

        # TEST
        ok (($trap->stdout() =~ m/\Q${color}\Eok\Q${reset}\E/), 
            "ok is colored") or mydiag();
            
    }

    {
        local $ENV{'PERL_HARNESS_VERDICT_COLORS'} = "success=magenta;failure=green";
        trap {
            system("runprove", 
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            );
        };

        my $color = color("magenta");
        my $reset = color("reset");

        # TEST
        ok (($trap->stdout() =~ m/\Q${color}\Eok\Q${reset}\E/), 
            "ok is colored in a different color") or mydiag();
            
    }

    {
        local $ENV{'PERL_HARNESS_VERDICT_COLORS'} = "failure=green;success=magenta";
        trap {
            system("runprove", 
                "t/sample-tests/one-ok.t",
                "t/sample-tests/several-oks.t"
            );
        };

        my $color = color("magenta");
        my $reset = color("reset");

        # TEST
        ok (($trap->stdout() =~ m/\Q${color}\Eok\Q${reset}\E/), 
            "ok is colored in a different color") or mydiag();
            
    }
}
