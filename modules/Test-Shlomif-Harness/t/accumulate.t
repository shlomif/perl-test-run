use strict;
use warnings;

use Test::More tests => 2;

package Base1;

use base 'Test::Run::Base';

sub _initialize
{
    return 0;
}

sub people
{
    return ["Sophie", "Jack"];
}

package Son1;

our @ISA = (qw(Base1));

sub people
{
    return ["Gabor", "Offer", "Shlomo"];
}

package Son2;

our @ISA = (qw(Base1));

sub people
{
    return ["Esther", "Xerces", "Mordeakhai"];
}

package Grandson1;

our @ISA = (qw(Son1));

sub people
{
    return ["David", "Becky", "Lisa"];
}

package main;

{
    my $grandson = Grandson1->new();

    # TEST
    is_deeply(
        $grandson->accum_array(
            {
                method => "people",
            },
        ),
        [qw(David Becky Lisa Gabor Offer Shlomo Sophie Jack)],
    );
}

{
    # TEST
    is_deeply(
        "Grandson1"->accum_array(
            {
                method => "people",
            },
        ),
        [qw(David Becky Lisa Gabor Offer Shlomo Sophie Jack)],
    );
}

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
