use strict;
use warnings;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;


my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::ColorSummary',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/Test/Run/Plugin/ColorSummary.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    build_requires =>
    {
        'Test::Run::Trap::Obj' => 0,
        'Test::Run::CmdLine::Trap::ProveApp' => 0,
    },
    requires => {
        'Test::More' => 0,
        'Term::ANSIColor' => 0,
        'Scalar::Util' => 0,
        'Test::Run::Obj' => 0,
        'Test::Run::Core' => '0.0118',
        'Test::Run::CmdLine' => '0.0111',
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-ColorSummary-*' ],
);

$builder->create_build_script();

