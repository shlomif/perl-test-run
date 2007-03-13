package Test::Run::Obj::FailedObj;

=head1 NAME

Test::Run::Obj::FailedObj - an object representing a failure.

=head1 DESCRIPTION

Inherits from Test::Run::Base::Struct.

=head1 METHODS

=cut.

use strict;
use warnings;

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

@fields = (qw(
    canon
    estat
    failed
    max
    name
    percent
    wstat
));

sub _get_fields
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

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

