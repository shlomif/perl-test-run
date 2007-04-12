package Test::Run::Plugin::CmdLine::Output;

use strict;
use warnings;

use Carp;
use Benchmark qw(timestr);
use NEXT;

use Test::Run::Core;

=head1 NAME

Test::Run::Plugin::CmdLine::Output - the default output plugin for
Test::Run::CmdLine.

=head1 MOTIVATION

This class will gradually re-implement all of the 
L<Test::Run::Plugin::CmdLine::Output::GplArt> functionality to 
avoid license complications. At the moment it inherits from it.

=cut


use base 'Test::Run::Plugin::CmdLine::Output::GplArt';

__PACKAGE__->mk_accessors(qw(
    output
));

=head1 LICENSE

This code is licensed under the MIT X11 License.

=cut

1;

