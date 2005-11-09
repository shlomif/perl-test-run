package Test::Run::Iterator;

use strict;
use vars qw($VERSION);
$VERSION = 0.02;

=head1 NAME

Test::Run::Iterator - Internal Test::Run Iterator

=head1 SYNOPSIS

  use Test::Run::Iterator;
  my $it = Test::Run::Iterator->new(\*TEST);
  my $it = Test::Run::Iterator->new(\@array);

  my $line = $it->next;

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY!>

This is a simple iterator wrapper for arrays and filehandles.

=head2 new()

Create an iterator.

=head2 next()

Iterate through it, of course.

=cut

sub new {
    my($proto, $thing) = @_;

    my $self = {};
    if( ref $thing eq 'GLOB' ) {
        bless $self, 'Test::Run::Iterator::FH';
        $self->{fh} = $thing;
    }
    elsif( ref $thing eq 'ARRAY' ) {
        bless $self, 'Test::Run::Iterator::ARRAY';
        $self->{idx}   = 0;
        $self->{array} = $thing;
    }
    else {
        warn "Can't iterate with a ", ref $thing;
    }

    return $self;
}

package Test::Run::Iterator::FH;
sub next {
    my $fh = $_[0]->{fh};

    # readline() doesn't work so good on 5.5.4.
    return scalar <$fh>;
}


package Test::Run::Iterator::ARRAY;
sub next {
    my $self = shift;
    return $self->{array}->[$self->{idx}++];
}

"Steve Peters, Master Of True Value Finding, was here.";
