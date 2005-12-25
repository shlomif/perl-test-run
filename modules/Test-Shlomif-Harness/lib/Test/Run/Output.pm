package Test::Run::Output;

use strict;
use warnings;

use base 'Class::Accessor';

__PACKAGE__->mk_accessors(qw(NoTty Verbose last_test_print ml));

=head1 NAME

Test::Run::Output - Base class for outputting messages to the user in a test
harmess.

=cut

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
    $self->NoTty($args{NoTty});
    return 0;
}

=head2 METHODS 

=over 4

=cut

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

=item B<_mk_leader>

  my($leader, $ml) = $self->_mk_leader($test_file, $width);

Generates the 't/foo........' leader for the given C<$test_file> as well
as a similar version which will overwrite the current line (by use of
\r and such).  C<$ml> may be empty if Test::Run doesn't think 
you're on TTY.

The C<$width> is the width of the "yada/blah.." string.

=cut

sub _mk_leader {
    my ($self, $te, $width) = @_;
    chomp($te);
    $te =~ s/\.\w+$/./;

    if ($^O eq 'VMS') {
        $te =~ s/^.*\.t\./\[.t./s;
    }
    my $leader = "$te" . '.' x ($width - length($te));
    my $ml = "";

    if ( -t STDOUT and not $self->NoTty() and not $self->Verbose()) {
        $ml = "\r" . (' ' x 77) . "\r$leader"
    }

    return($leader, $ml);
}

=back

=head1 AUTHOR

Shlomi Fish (shlomif@iglu.org.il)

=cut

1;

