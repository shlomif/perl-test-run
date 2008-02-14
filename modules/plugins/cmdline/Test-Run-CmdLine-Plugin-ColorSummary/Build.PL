use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::CmdLine::Plugin::ColorSummary',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/Test/Run/CmdLine/Plugin/ColorSummary.pm',
    requires => {
        'Test::More' => 0,
        'Test::Run::CmdLine' => 0,
        'Test::Run::Plugin::ColorSummary' => 0,
    },
    add_to_cleanup      => [ 'Test-Run-CmdLine-Plugin-ColorSummary-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
