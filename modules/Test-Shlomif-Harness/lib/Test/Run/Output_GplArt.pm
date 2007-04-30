package Test::Run::Output_GplArt;

use strict;
use warnings;

use base 'Test::Run::Base';

=head2 METHODS 

=over 4

=cut

=item B<_mk_leader>

  my($leader, $ml) = $self->_mk_leader($test_file, $width);

Generates the 't/foo........' leader for the given C<$test_file> as well
as a similar version which will overwrite the current line (by use of
\r and such).  C<$ml> may be empty if Test::Run doesn't think 
you're on TTY.

The C<$width> is the width of the "yada/blah.." string.

=cut

sub _mk_leader
{
    my ($self, $_pre_te, $width) = @_;

    my $te = $self->_mk_leader__calc_te($_pre_te);

    chomp($te);
    $te =~ s/\.\w+$/./;

    if ($^O eq 'VMS') {
        $te =~ s/^.*\.t\./\[.t./s;
    }

    
    my $leader = "$te" . '.' x ($width - length($te));
    my $ml = "";

    if ( -t STDOUT and not $self->NoTty() and not $self->Verbose())
    {
        $ml = "\r" . (' ' x 77) . "\r$leader";
    }

    $self->ml($ml);

    return $leader;
}

=back

=head1 AUTHOR

Shlomi Fish (shlomif@iglu.org.il)

=cut

1;

