# This file is under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php

use strict;
use warnings;

use File::Spec;
use lib File::Spec->catdir(File::Spec->curdir(), "inc");

use Test::Run::Builder;

my $build = Test::Run::Builder->new(
    module_name => "Test::Run::CmdLine",
    build_requires =>
    {
        "Test::Trap" => 0,
        'Test::More' => 0,        
    },
    requires => 
    {
        'Test::Run::Core' => "0.0117",
        'UNIVERSAL::require' => 0,
    },
    dist_version_from => 'lib/Test/Run/CmdLine.pm',
    license => "mit",
    script_files => [ "bin/runprove", ],
    create_makefile_pl => "traditional",
);

$build->create_build_script;

