package Test::Run::Plugin::CollectStats::TestFileData;

use strict;
use warnings;

=head1 NAME

Test::Run::Plugin::CollectStats::TestFileData - an object representing the
data for a single test file in Test::Run.

=head1 VERSIO

Version 0.01

=cut

use base 'Test::Run::Base::Struct';

my @fields = 
(qw(
    elapsed_time
    results
    summary_object
));

__PACKAGE__->mk_accessors(@fields);

sub _get_fields
{
    return [@fields];
}

1;

__END__

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-collectstats at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Run-Plugin-CollectStats>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::CollectStats

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Run-Plugin-CollectStats>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Run-Plugin-CollectStats>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Run-Plugin-CollectStats>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Run-Plugin-CollectStats>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT/X11.

=cut

