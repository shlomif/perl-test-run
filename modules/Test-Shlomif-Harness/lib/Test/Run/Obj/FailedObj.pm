package Test::Run::Obj::FailedObj;

=head1 NAME

Test::Run::Obj::FailedObj - an object representing a failure.

=head1 DESCRIPTION

Inherits from Test::Run::Base::Struct.

=head1 METHODS

=cut

use strict;
use warnings;

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

@fields = (qw(
    canon
    canon_strings
    estat
    failed
    list_len
    max
    name
    percent
    wstat
));

sub _get_private_fields
{
    return [@fields];
}

__PACKAGE__->mk_accessors(@fields);

=head2 $self->_defined_percent()

Returns a defined percentage. It returns the percentage or 0 if it is 
undefined.

=cut

sub _defined_percent
{
    my $self = shift;

    return defined($self->percent()) ? $self->percent() : 0;
}

sub _do_canon_concat
{
    my ($self, $ret, $canon) = @_;

    my $first = shift(@$canon);

    my $new_last_ret = "$ret->[-1] $first";

    if (length($new_last_ret) < $self->list_len())
    {
        $ret->[-1] = $new_last_ret;
    }
    else
    {
        push @$ret, $first;
    }
}

sub _calc_stringification
{
    my ($self, $canon) = @_;

    my @ret = shift(@$canon);

    while (@$canon)
    {
        $self->_do_canon_concat(\@ret, $canon);
    }

    return \@ret;
}

sub _assign_canon_strings
{
    my $self = shift;

    my $args = shift;

    $self->list_len($args->{main}->list_len());

    $self->canon_strings(
        $self->_calc_stringification(
            [ split /\s+/, $self->canon() ],
        )
    );
}

=head2 $self->first_canon_string()

The first of the canon_strings(). (With index 0).

=cut

sub first_canon_string
{
    my $self = shift;

    return $self->canon_strings()->[0];
}

=head2 $self->rest_of_canons()

An array reference containing all the canons except the 0th.

=cut

sub rest_of_canons
{
    my $self = shift;

    my $canons = $self->canon_strings();

    return [ @{$canons}[ 1 .. ($#$canons-1) ] ];
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

