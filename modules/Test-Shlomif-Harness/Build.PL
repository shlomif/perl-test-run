# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Test::Run",
    build_requires =>
    {
        "Test::Trap" => 0,
    },
    requires => 
    {
        'Class::Accessor' => 0,
        'File::Spec' => 0.6,
        'List::Util' => 0,
        'List::MoreUtils' => 0,
        'MRO::Compat' => 0,
        'Scalar::Util' => 0,
        'TAP::Parser' => "3.09",
        'Test::Harness' => "2.53",
        'Text::Sprintf::Named' => '0.02',
        'UNIVERSAL::require' => 0,
    },
    dist_version_from => "lib/Test/Run/Core.pm",
    license => "mit",
    create_makefile_pl => 'traditional',
);

$build->create_build_script;

