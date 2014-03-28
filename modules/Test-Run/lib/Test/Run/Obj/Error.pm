=head1 NAME

Test::Run::Obj::Error - an error class hierarchy for Test::Run.

=head1 DESCRIPTION

This module provides an error class hieararchy for Test::Run. This is used
for throwing exceptions that should be handled programatically.

=head1 METHODS
=cut


package Test::Run::Obj::Error;

use strict;
use warnings;

use MooX qw( late );

use Test::Run::Base::Struct;

use Scalar::Util ();

use vars qw(@ISA @fields);

use MRO::Compat;


sub _polymorphic_stringify
{
    my $self = shift;
    return $self->stringify(@_);
}

use overload
    '""' => \&_polymorphic_stringify,
    'fallback' => 1
    ;

extends(qw(Test::Run::Base::Struct));

has 'package' => (is => "rw", isa => "Str");
has 'file' => (is => "rw", isa => "Str");
has 'line' => (is => "rw", isa => "Num");
has 'text' => (is => "rw", isa => "Str");

=head2 BUILD

For Moo.

=cut

sub BUILD
{
    my $self = shift;

    my ($pkg,$file,$line) = caller(1);
    $self->package($pkg);
    $self->file($file);
    $self->line($line);
}

=head2 $self->stringify()

Stringifies the error. Returns the text() field by default.

=cut

sub stringify
{
    my $self = shift;
    return $self->text();
}

1;

package Test::Run::Obj::Error::TestsFail;

$INC{'Test/Run/Obj/Error/TestsFail.pm'} = './Test/Run/Obj/Error/TestsFail.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error));

package Test::Run::Obj::Error::TestsFail::NoTestsRun;

$INC{'Test/Run/Obj/Error/TestsFail/NoTestsRun.pm'} = './Test/Run/Obj/Error/TestsFail/NoTestsRun.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::Other;

$INC{'Test/Run/Obj/Error/TestsFail/Other.pm'} = './Test/Run/Obj/Error/TestsFail/Other.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::NoOutput;

$INC{'Test/Run/Obj/Error/TestsFail/NoOutput.pm'} = './Test/Run/Obj/Error/TestsFail/NoOutput.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::Bailout;

$INC{'Test/Run/Obj/Error/TestsFail/Bailout.pm'} = './Test/Run/Obj/Error/TestsFail/Bailout.pm';

use MooX qw( late );


extends(qw(Test::Run::Obj::Error::TestsFail));

has 'bailout_reason' => (is => "rw", isa => "Str");

sub stringify
{
    my $self = shift;
    return "FAILED--Further testing stopped" .
        ($self->bailout_reason() ?
            (": " . $self->bailout_reason() . "\n") :
            ".\n"
        );
}

package Test::Run::Obj::Error::Straps;

$INC{'Test/Run/Obj/Error/Straps.pm'} = './Test/Run/Obj/Error/Straps.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error));

package Test::Run::Obj::Error::Straps::CannotRunPerl;

$INC{'Test/Run/Obj/Error/Straps/CannotRunPerl.pm'} = './Test/Run/Obj/Error/Straps/CannotRunPerl.pm';

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::Straps));

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

