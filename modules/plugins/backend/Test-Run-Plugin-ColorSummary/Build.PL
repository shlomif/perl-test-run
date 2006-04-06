use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Run::Plugin::ColorSummary',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@iglu.org.il>',
    dist_version_from   => 'lib/Test/Run/Plugin/ColorSummary.pm',
    requires => {
        'Test::More' => 0,
        'Term::ANSIColor' => 0,
        'Scalar::Util' => 0,
        'Test::Run::Obj' => 0,
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-ColorSummary-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

