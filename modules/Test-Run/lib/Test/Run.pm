package Test::Run;

use strict;
use warnings;

=head1 NAME

Test::Run - a new and improved test harness for TAP scripts.

=head1 SYNPOSIS

    cpanp -i Task::Test::Run::AllPlugins
    export HARNESS_PLUGINS="ColorSummary ColorFileVerdicts"
    runprove t/*.t

=head1 ABOUT

Test::Run is an improved test harness, originally based on L<Test::Harness>
version 2.xx by Michael G. Schwern, Andy Lester and others.

The top-level "Test::Run" by itself does not do much. You should refer
to L<Task::Test::Run::AllPlugins> for more detailed instructions.

The rest of this page contains some information and links about Test::Run.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run

You can also look for information at:

=over 4

=item * Homepage

L<http://web-cpan.berlios.de/modules/Test-Run/>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run>

=item * Search CPAN

L<http://search.cpan.org/dist/Test::Run>

=item * Subversion Repository

L<http://svn.berlios.de/svnroot/repos/web-cpan/Test-Harness-NG/trunk/>

=back

=head1 LINKS

=over 4

=item * L<http://testanything.org/wiki/index.php/Test::Run>

Test::Run on the Test Anything Protocol wiki.

=item * L<http://testanything.org/wiki/index.php/TAP_Consumers>

Other TAP consumers.

=item * L<Test::Tutorial>

Learn how to write Perl tests.

=back

=head1 ACKNOWLEDGEMENTS

The (possibly ad-hoc) regex for matching the optional digits+symbols 
parameters' prefix of the sprintf conversion was originally written by Bart 
Lateur (BARTL on CPAN) for his L<String::Sprintf> module.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Run
