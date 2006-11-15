package Test::Run::Obj;

use strict;
use warnings;

use vars qw(@ISA $VERSION);

use Test::Run::Core;
use Test::Run::Plugin::CmdLine::Output;

=head1 NAME

Test::Run::Obj - Run Perl standard test scripts with statistics

=head1 VERSION

Version 0.0100_09

=cut

$VERSION = "0.0101";

@ISA = (qw(
    Test::Run::Plugin::CmdLine::Output
    Test::Run::Core
    ));

1;
