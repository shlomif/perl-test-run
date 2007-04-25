package Test::Run::Obj::CanonFailedObj;

use strict;
use warnings;

use base 'Test::Run::Obj::CanonFailedObj_GplArt';

use vars qw(@fields);

@fields = (qw(
    canon
    failed_num
    result
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
