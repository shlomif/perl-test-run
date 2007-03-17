use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::CollectStats',
    license             => 'bsd',
    dist_author         => 'Shlomi Fish <shlomif@cpan.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/CollectStats.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'Test::Run::Core' => '0.0106',
        'NEXT' => 0,
        'Storable' => 0,
        'Test::Run::Base::Struct' => 0,
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-CollectStats-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
