#!/usr/bin/perl 

use strict;
use warnings;

LINES: while(my $line = <>)
{
    print $line;
    if ($line =~ /^ +\{/)
    {
        my $rp_line = <>;
        if ($rp_line =~ m{^( +)my \$results = qx\{\$runprove ([^\}]*)\};})
        {
            my ($ws, $cl) = ($1, $2);
            my $tab = " " x 4;
            print "${ws}my \$got = TestRunCmdLineTrapper->new(\n" 
                . "${ws}${tab}\{\n"
                . "${ws}${tab}${tab}runprove => \$runprove,\n"
                . "${ws}${tab}${tab}cmdline => qq{${cl}},\n"
                . "${ws}${tab}\}\n"
                . "${ws});\n"
        }
        else
        {
            print $rp_line;
            next LINES;
        }
    }
}

