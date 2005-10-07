package Test::Shlomif::Harness::Output;

use strict;
use warnings;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(Verbose last_test_print ml));

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize
{
    my $self = shift;
    my (%args) = @_;
    $self->Verbose($args{Verbose});
    return 0;
}

sub _print_message_raw
{
    my ($self, $msg) = @_;
    print $msg;
}

sub print_message
{
    my ($self, $msg) = @_;
    $self->_print_message_raw($msg);
    print "\n";
}

sub print_leader
{
    my $self = shift;
    my (%args) = @_;
    my ($leader, $ml) =
        $self->_mk_leader(
            $args{filename},
            $args{width},
        );
    $self->ml($ml);
    $self->_print_message_raw(
        $leader,
    );
}

sub print_ml
{
    my $self = shift;
    my $msg = shift;
    if ($self->ml())
    {
        $self->_print_message_raw($self->ml(). $msg);
    }
}

# Print updates only once per second.
sub print_ml_less {
    my $self = shift;
    my $now = CORE::time;
    if ( $self->last_test_print() != $now ) {
        $self->print_ml(@_);
        $self->last_test_print($now);
    }
}

sub _mk_leader {
    my ($self, $te, $width) = @_;
    chomp($te);
    $te =~ s/\.\w+$/./;

    if ($^O eq 'VMS') {
        $te =~ s/^.*\.t\./\[.t./s;
    }
    my $leader = "$te" . '.' x ($width - length($te));
    my $ml = "";

    if ( -t STDOUT and not $ENV{HARNESS_NOTTY} and not $self->Verbose()) {
        $ml = "\r" . (' ' x 77) . "\r$leader"
    }

    return($leader, $ml);
}

1;

