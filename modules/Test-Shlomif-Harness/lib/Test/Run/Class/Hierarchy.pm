package Test::Run::Class::Hierarchy;

use strict;
use warnings;

use base 'Exporter';
use List::MoreUtils (qw(uniq));

our @EXPORT_OK = (qw(hierarchy_of rev_hierarchy_of));

our %_hierarchy_of = ();

sub hierarchy_of
{
    my $class = shift;

    if (exists($_hierarchy_of{$class}))
    {
        return $_hierarchy_of{$class};
    }

    no strict 'refs';

    my @hierarchy = $class;
    my @parents = @{$class. '::ISA'};

    while (my $p = shift(@parents))
    {
        push @hierarchy, $p;
        push @parents, @{$p. '::ISA'};
    }

    my @unique = uniq(@hierarchy);

    return $_hierarchy_of{$class} =
        [
            sort
            {
                  $a->isa($b) ? -1
                : $b->isa($a) ? +1
                :               0 
            }
            @unique
        ];
}

our %_rev_hierarchy_of = ();

sub rev_hierarchy_of
{
    my $class = shift;

    if (exists($_rev_hierarchy_of{$class}))
    {
        return $_rev_hierarchy_of{$class};
    }

    return $_rev_hierarchy_of{$class} = [reverse @{hierarchy_of($class)}];
}

1;


=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 CREDITS

The code was inspired by the code from Damian Conway's L<Class::Std>, but
is not inclusive of it.

Writen by Shlomi Fish: L<http://www.shlomifish.org/>.

=cut

