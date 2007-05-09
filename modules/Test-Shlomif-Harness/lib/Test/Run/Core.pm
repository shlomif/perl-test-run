package Test::Run::Core;

use strict;
use warnings;

use base 'Test::Run::Core_GplArt';

use vars qw($VERSION);

=head1 NAME

Test::Run::Core - Base class to run standard TAP scripts.

=head1 VERSION

Version 0.0110

=cut

$VERSION = '0.0110';

$ENV{HARNESS_ACTIVE} = 1;
$ENV{HARNESS_NG_VERSION} = $VERSION;

END
{
    # For VMS.
    delete $ENV{HARNESS_ACTIVE};
    delete $ENV{HARNESS_NG_VERSION};
}

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
