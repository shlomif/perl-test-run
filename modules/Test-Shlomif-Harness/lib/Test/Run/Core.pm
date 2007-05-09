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

sub _calc_strap_callback_map
{
    return 
    {
        "tap_event"        => "_tap_event_strap_callback",
        "report_start_env" => "_report_script_start_environment",
        "could_not_run_script" => "_report_could_not_run_script",
        "test_file_opening_error" => "_handle_test_file_opening_error",
        "test_file_closing_error" => "_handle_test_file_closing_error",
    };
}

sub _strap_callback
{
    my ($self, $args) = @_;
    
    my $type = $args->{type};
    my $cb = $self->_calc_strap_callback_map()->{$type};

    return $self->$cb($args);
}

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=cut
