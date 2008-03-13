package Test::Run::Straps::Base;

use strict;
use warnings;

=head1 NAME

Test::Run::Straps::Base - base class for some Straps-related classes.

=head1 DESCRIPTION

This class serves to abstract the common functionality between
L<Test::Run::Straps> and L<Test::Run::Straps::StrapsTotalsObj>.

=cut

use Test::Run::Base;

use base 'Test::Run::Base::Struct';

use vars qw(@fields);

@fields = (qw(
    _event
    _is_vms
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

sub _is_event_pass
{
    my $self = shift;

    return $self->_event->is_pass();
}

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish <shlomif@iglu.org.il>

=cut

1;

