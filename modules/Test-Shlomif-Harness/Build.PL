use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Test::Run",
    requires => 
    {
        'Class::Accessor' => 0,
        'File::Spec' => 0.6,
        'Test::Harness' => "2.53",
        'Scalar::Util' => 0,
        'TAPx::Parser' => "0.30",
        'NEXT' => 0,
    },
    dist_version_from => "lib/Test/Run/Core.pm",
    license => "perl",
);

$build->create_build_script;

