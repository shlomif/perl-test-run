package Test::Run::Plugin::TrimDisplayedFilenames;

use warnings;
use strict;

use NEXT;

use base 'Test::Run::Base';
use base 'Class::Accessor';

=head1 NAME

Test::Run::Plugin::TrimDisplayedFilenames - trim the first components
of the displayed filename to deal with excessively long ones.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(qw(
    trim_displayed_filenames_query
));

sub _get_private_simple_params
{
    my $self = shift;
    return [qw(trim_displayed_filenames_query)];
}

=head1 SYNOPSIS

    package MyTestRun;

    use base 'Test::Run::Plugin::TrimDisplayedFilenames';
    use base 'Test::Run::Obj';

=head1 FUNCTIONS

=cut

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-run-plugin-alternateinterpreters at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test::Run::Plugin::TrimDisplayedFilenames>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Run::Plugin::TrimDisplayedFilenames

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test::Run::Plugin::TrimDisplayedFilenames>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test::Run::Plugin::TrimDisplayedFilenames>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test::Run::Plugin::TrimDisplayedFilenames>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Run-Plugin-TrimDisplayedFilenames/>

=back

=head1 ACKNOWLEDGEMENTS

Curtis "Ovid" Poe ( L<http://search.cpan.org/~ovid/> ) who gave the idea
of testing several tests from several interpreters in one go here:

L<http://use.perl.org/~Ovid/journal/32092>

=head1 SEE ALSO

L<Test::Run>, L<Test::Run::CmdLine>, L<TAP::Parser>,
L<Test::Run::CmdLine::Plugin::TrimDisplayedFilenames>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

=cut

1; # End of Test::Run::Plugin::TrimDisplayedFilenames
