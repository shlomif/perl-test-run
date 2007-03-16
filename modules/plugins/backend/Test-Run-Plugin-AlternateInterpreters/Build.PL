use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Test::Run::Plugin::AlternateInterpreters',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/AlternateInterpreters.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Test::Run::CmdLine' => 0,
        'Test::Run::Core' => "0.0105",
        'YAML' => 0,
        'NEXT' => 0,
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-AlternateInterpreters-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
