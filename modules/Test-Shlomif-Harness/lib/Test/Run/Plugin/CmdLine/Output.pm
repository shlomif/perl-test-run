package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

=head1 NAME

Test::Run::Plugin::CmdLine::Output - the default output plugin for
Test::Run::CmdLine.

=head1 MOTIVATION

This class will gradually re-implement all of the 
L<Test::Run::Plugin::CmdLine::Output::GplArt> functionality to 
avoid license complications. At the moment it inherits from it.

=cut


use base 'Test::Run::Plugin::CmdLine::Output::GplArt';

1;

=head1 LICENSE

This code is licensed under the MIT X11 License.

=cut

