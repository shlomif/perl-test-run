use strict;
use warnings;

use Test::More tests => 1;

use File::Spec;

use Test::Trap qw( trap $trap :flow:stderr(systemsafe):stdout(systemsafe):warn );

BEGIN
{
    $SIG{__WARN__} = sub { die $_[0] };
}

package MyTestRun;

use base 'Test::Run::Obj';

sub _init_strap
{
    my ($self, $args) = @_;
    $self->NEXT::_init_strap($args);

    my $test_file = $args->{test_file};

    if ($test_file =~ /\.mok\z/)
    {
        $self->Strap()->Test_Interpreter(
            "$^X " .
            File::Spec->catfile(
                File::Spec->curdir(), "t", "data", "interpreters",
                "wrong-mini-ok.pl"
            ).
            " "
        );
        $self->Strap()->Switches("");
        $self->Strap()->Switches_Env("");
    }
}

package main;

{
    trap {
        my $tester = 
            MyTestRun->new(
                test_files => 
                [
                    "t/sample-tests/simple",
                    "t/sample-tests/success1.mok",
                ],
            );
        $tester->runtests();
    };

    # TEST
    ok ($trap->stderr() !~ /sprintf/, 
        "No warning for undefined sprintf argument was emitted."
    );
}

