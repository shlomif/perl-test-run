use strict;
use warnings;

use Test::More tests => 4;

use Test::Run::Base;

package MyTestRun::Plug::Iface;

package MyTestRun::Pluggable;

use base 'Test::Run::Base::PlugHelpers';

use NEXT;

sub _initialize
{
    my $self = shift;

    $self->NEXT::_initialize(@_);

    $self->register_pluggable_helper(
        {
            id => "myplug",
            base => "MyTestRun::Plug::Base",
            collect_plugins_method => "_my_plugin_collector",
        }
    );
}

sub _my_plugin_collector
{
    return
    [
        "MyTestRun::Plug::P::One", 
        "MyTestRun::Plug::P::Two",
    ];
}

package main;

use lib "./t/lib";

{
    my $main_obj = MyTestRun::Pluggable->new({});

    my $obj = $main_obj->create_pluggable_helper_obj(
        {
            id => "myplug",
            into => "MyTestRun::Plug::Iface",
            args => 
            {
                first => "Aharon",
                'last' => "Smith",
            },
        }
    );

    # TEST
    is_deeply(\@MyTestRun::Plug::Iface::ISA,
        [qw(
            MyTestRun::Plug::P::One
            MyTestRun::Plug::P::Two
            MyTestRun::Plug::Base
        )],
        "Good \@ISA for the iface class."
    );

    # TEST
    isa_ok ($obj, "MyTestRun::Plug::Iface");

    # TEST
    is ($obj->my_calc_first(),
        "First is {{{Aharon}}}",
    );

    # TEST
    is ($obj->my_calc_last(),
        "If you want the last name, it is: Smith"
    );
}
