package Test::Run::Straps::StrapsDetailsObj;

use strict;
use warnings;

=head1 NAME

Test::Run::Straps::StrapsDetailsObj - a struct representing the details of
the straps class.

=head1 DESCRIPTIONS

Inherits from Test::Run::Base::Struct.

=head1 METHODS

=cut

use vars qw(@fields);

use base 'Test::Run::Base::Struct';

@fields = (qw(
    actual_ok
    diagnostics
    name
    ok
    reason
    type
));

sub _get_private_fields
{
    return [@fields];
}

sub _pre_init
{
    my $self = shift;
    $self->diagnostics("");
}

__PACKAGE__->mk_accessors(@fields);

=head2 $self->append_to_diag($text)

Appends $text to the diagnostics.

=cut

sub append_to_diag
{
    my ($self, $text) = @_;
    $self->diagnostics($self->diagnostics().$text);
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the terms of the MIT X11 License.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut

