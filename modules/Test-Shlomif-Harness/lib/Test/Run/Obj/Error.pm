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

@ISA = (qw(Test::Run::Base::Struct));

@fields = (qw(
    package
    file
    line
    text
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub _init
{
    my $self = shift;

    # Workaround to make next::method behave.
    # It misbehaves upon a stringification operation.
    $self->text(Scalar::Util::refaddr($self));

    $self->next::method(@_);

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

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error));

package Test::Run::Obj::Error::TestsFail::NoTestsRun;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::Other;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::NoOutput;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

package Test::Run::Obj::Error::TestsFail::Bailout;

use vars qw(@ISA @fields);

sub _get_private_fields
{
    my $self = shift;

    return [@fields];
}

@ISA = (qw(Test::Run::Obj::Error::TestsFail));

@fields = (qw(bailout_reason));

__PACKAGE__->mk_accessors(@fields);

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

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error));

package Test::Run::Obj::Error::Straps::CannotRunPerl;

use vars qw(@ISA);

@ISA = (qw(Test::Run::Obj::Error::Straps));

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

