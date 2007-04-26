package Test::Run::Straps::StrapsTotalsObj;

use strict;
use warnings;

use base 'Test::Run::Straps::StrapsTotalsObj_GplArt';

use vars qw(@fields);

@fields = (qw(
    bonus
    details
    _enormous_num_cb
    _event
    exit
    filename
    max
    ok
    passing
    seen
    skip
    skip_all
    skip_reason
    todo
    wait
));

sub _get_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut

1;

