package Test::Run::Straps;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.26';

=head1 NAME

Test::Run::Straps - analyse the test results by using TAP::Parser.

=head1 METHODS

=cut

use base 'Test::Run::Straps_GplArt';

use Test::Run::Straps::EventWrapper;

use Test::Run::Obj::Error;

my @fields= (qw(
    bailout_reason
    callback
    Debug
    error
    exception
    file
    _file_handle
    _file_totals
    _is_macos
    _is_vms
    _is_win32
    last_test_print
    lone_not_line
    max
    next
    _old5lib
    _parser
    results
    saw_bailout
    saw_header
    _seen_header
    Switches
    Switches_Env
    Test_Interpreter
    todo
    too_many_tests
    totals
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);


=head2 my $strap = Test::Run::Straps->new();

Initialize a new strap.

=cut

sub _initialize
{
    my $self = shift;

    $self->NEXT::_initialize(@_);

    $self->_is_vms($^O eq "VMS");
    $self->_is_win32($^O =~ m{\A(?:MS)?Win32\z});
    $self->_is_macos($^O eq "MacOS");

    $self->totals(+{});
    $self->todo(+{});

    return 0;
}

sub _start_new_file
{
    my $self = shift;

    $self->_reset_file_state;
    my $totals =
        $self->_init_totals_obj_instance(
            $self->_get_initial_totals_obj_params(),
        );

    $self->_file_totals($totals);

    # Set them up here so callbacks can have them.
    $self->totals()->{$self->file()}         = $totals;

    return;
}

sub _calc_next_event
{
    my $self = shift;

    my $event = scalar($self->_parser->next());

    if (defined($event))
    {
        return 
            Test::Run::Straps::EventWrapper->new(
                {
                    event => $event,
                },
            );
    }
    else
    {
        return undef;
    }
}

sub _get_next_event
{
    my ($self) = @_;

    return $self->_event($self->_calc_next_event());
}

sub _get_event_types_cascade
{
    return [qw(test plan bailout comment)];
}

=head2 $self->_handle_event()

Handles the current event according to the list of types in the cascade. It
checks each type and if matches calls the appropriate 
C<_handle_${type}_event> callback. Returns the type of the event that matched.

=cut

sub _handle_event
{
    my $self = shift;

    my $event = $self->_event;

    foreach my $type (@{$self->_get_event_types_cascade()})
    {
        my $is_type = "is_" . $type;
        if ($event->$is_type())
        {
            my $handle_type = "_handle_${type}_event";
            $self->$handle_type();

            return $type;
        }
    }

    return;
}

sub _invoke_cb
{
    my $self = shift;
    my $args = shift;

    if ($self->callback())
    {
        $self->callback()->(
            $args
        );
    }
}

sub _bump_next
{
    my $self = shift;

    if (defined(my $n = $self->_event->get_next_test_number()))
    {
        $self->next($n);
    }

    return;
}


sub _calc__analyze_event__callbacks
{
    my $self = shift;

    return [qw(
        _handle_event
        _call_callback
        _bump_next
    )];
}

sub _analyze_event
{
    shift->_run_sequence();

    return;
}

sub _end_file
{
    my $self = shift;

    $self->_file_totals->determine_passing();

    $self->_parser(undef);
    $self->_event(undef);

    return;
}

sub _calc__analyze_with_parser__callbacks
{
    my $self = shift;

    return [qw(
        _start_new_file
        _events_loop
        _end_file
    )];
}

sub _analyze_with_parser
{
    my $self = shift;

    $self->_run_sequence();

    return $self->_file_totals();
}

sub _create_parser
{
    my ($self, $source) = @_;
    return TAP::Parser->new(
            {
                source => $source,
            }
        );
}

=head2 my $results = $self->analyze( $name, \@output_lines)

Analyzes the output @output_lines of a given test, to which the name
$name is assigned. Returns the results $results of the test - an object.

@output_lines should be the output of the test including newlines.

=cut

sub analyze
{
    my($self, $name, $test_output_orig) = @_;

    # Assign it here so it won't be passed around.
    $self->file($name);

    $self->_parser($self->_create_parser($test_output_orig));

    return $self->_analyze_with_parser();
}

sub _init_totals_obj_instance
{
    my ($self, $args) = @_;
    return Test::Run::Straps::StrapsTotalsObj->new($args);
}

sub _get_initial_totals_obj_params
{
    my $self = shift;

    return
    {
        (map { $_ => 0 } qw(max seen ok todo skip bonus)),
        filename => $self->file(),
        details => [],
    };
}

sub _is_event_todo
{
    my $self = shift;

    return $self->_event->has_todo();
}

sub _analyze_fh_wrapper
{
    my $self = shift;

    eval
    {
        $self->results($self->analyze_fh());
    };
    $self->exception($@);

    return;
}

sub _default_inc
{
    my $self = shift;

    # Temporarily nullify PERL5LIB so Perl will not report the paths
    # that it contains.
    local $ENV{PERL5LIB};

    my $perl_includes;

    if (!open ($perl_includes, "-|", $^X, "-e", qq{print join("\\n", \@INC);}))
    {
        die Test::Run::Obj::Error::Straps::CannotRunPerl->new(
            {text => "Cannot invoke \"$^X\" for determining includes"}
        );
    }
    
    my @includes;
    while (my $inc = <$perl_includes>)
    {
        chomp($inc);
        push @includes, $inc;
    }
    close($perl_includes);

    return \@includes;
}

1;


=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 AUTHOR

Shlomi Fish <shlomif@iglu.org.il>
