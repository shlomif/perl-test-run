use strict;
use warnings;

use Test::More tests => 1;

use File::Spec;

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

sub trap_output
{
    my $args = shift;

    open ALTOUT, ">", "altout.txt";
    open SAVEOUT, ">&STDOUT";
    open STDOUT, ">&ALTOUT";


    my $tester = ($args->{class} || "Test::Run::Obj")->new(
        {@{$args->{args}}},
        );

    eval { $tester->runtests(); };

    my $error = $@;

    open STDOUT, ">&SAVEOUT";
    close(SAVEOUT);
    close(ALTOUT);

    my $text = do { local $/; local *I; open I, "<", "altout.txt"; <I>};

    return
    {
        'stdout' => $text,
        'error' => $error,
    }
}

{
    my $got = trap_output(
        {
            class => "MyTestRun",
            args =>
            [
                test_files => 
                [
                    "t/sample-tests/simple",
                    "t/sample-tests/success1.mok",
                ],
            ],
        }
    );

    # TEST
    ok (($got->{error} !~ /sprintf/), 
        "No warning for undefined sprintf argument was emitted."
    );
}

