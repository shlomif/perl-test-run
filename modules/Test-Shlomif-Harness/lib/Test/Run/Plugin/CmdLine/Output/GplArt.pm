package Test::Run::Plugin::CmdLine::Output::GplArt;

use strict;
use warnings;

use Carp;
use NEXT;

use Test::Run::Core;

=head1 Test::Run::Plugin::CmdLine::Output::GplArt

This a module that implements the command line/STDOUT specific output of 
L<Test::Run::Obj>, which was taken out of L<Test::Run::Core> to increase
modularity.

=head1 MOTIVATION

This module implements the legacy code of the plugin as inherited from
Test::Harness. It has a derived class called 
L<Test::Run::Plugin::CmdLine::Output> that was written from scratch and
implements a new code under the MIT X11 license.

=cut

use base 'Test::Run::Core';

=head1 LICENSE

This module is licensed under the GPL v2 or later or the Artistic license
(original only) and is copyrighted by Larry Wall, Michael G. Schwern, Andy
Lester and others.

=cut
1;
