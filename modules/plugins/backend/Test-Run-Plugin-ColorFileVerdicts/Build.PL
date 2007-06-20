use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::ColorFileVerdicts',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/ColorFileVerdicts.pm',
    build_requires => {
        'Test::More' => 0,
        'Test::Run::Trap::Obj' => 0,
        'Test::Run::CmdLine::Trap::ProveApp' => 0,
    },
    requires => {
        "Term::ANSIColor" => 0,
        "Test::Run::Core" => "0.0111",
        "Test::Run::CmdLine" => "0.0105",
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-ColorFileVerdicts-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
