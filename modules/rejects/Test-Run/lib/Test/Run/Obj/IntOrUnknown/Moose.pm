package Test::Run::Obj::IntOrUnknown::Moose;

=head1 NAME

Test::Run::Obj::IntOrUnknown::Moose - export has_IntOrUnknown .

=head1 VERSION

Version 0.0302

=head1 DESCRIPTION

This is a Moose::Exporter-based extension that exports the has_IntOrUnknown
convenience function to add an attribute.


=cut

use strict;
use warnings;

use Moose ();
use Moose::Exporter;

use vars qw($VERSION);

$VERSION = '0.0302';

Moose::Exporter->setup_import_methods(
      with_caller => [ 'has_IntOrUnknown' ],
);

=head1 FUNCTIONS

=head2 has_IntOrUnknown $name => (%extra_options)

Adds a L<Test::Run::Obj::IntOrUnknown> field called $name. C<${name}_str>
will return a stringified version of it.

=cut

sub has_IntOrUnknown {
    my ($caller, $name, %options) = @_;
    if (!exists($options{'handles'})) {
        $options{'handles'} = {};
    }
    $options{'handles'}->{$name."_str"} = "get_string_val";
    Class::MOP::class_of($caller)->add_attribute(
        $name,
        is => "rw",
        isa => "Test::Run::Obj::IntOrUnknown",
        %options,
    );
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Obj::IntOrUnknown>, L<Moose::Exporter> .

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 COPYRIGHT

Copyrighted by Shlomi Fish, 2009.

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut
