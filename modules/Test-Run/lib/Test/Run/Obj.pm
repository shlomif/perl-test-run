package Test::Run::Obj;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

use Test::Run::Core;
use Test::Run::Plugin::CmdLine::Output;

=head1 NAME

Test::Run::Obj - Run Perl standard test scripts with statistics

=head1 VERSION

Version 0.0121

=cut

$VERSION = "0.0121";

@ISA = (qw(
    Test::Run::Plugin::CmdLine::Output
    Test::Run::Core
    ));

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

