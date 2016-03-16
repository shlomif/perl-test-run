use strict;
use warnings;
use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $builder = Test::Run::Builder->new(
    module_name         => 'Test::Run::Plugin::FailSummaryComponents',
    license             => 'mit',
    dist_author         => 'Shlomi Fish <shlomif@shlomifish.org>',
    dist_version_from   => 'lib/Test/Run/Plugin/FailSummaryComponents.pm',
    configure_requires =>
    {
        'Module::Build' => '0.36',
    },
    build_requires =>
    {
        'Test::Trap' => 0,
    },
    requires => {
        'perl' => '5.008',
        'Test::More' => 0,
        'Term::ANSIColor' => 0,
        'Scalar::Util' => 0,
        'Test::Run::Obj' => 0,
    },
    meta_merge =>
    {
        resources =>
        {
            homepage => "http://web-cpan.shlomifish.org/modules/Test-Run/",
            repository => "https://bitbucket.org/shlomif/perl-test-run",
        },
    },
    add_to_cleanup      => [ 'Test-Run-Plugin-FailSummaryComponents-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();

