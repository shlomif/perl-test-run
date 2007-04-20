# This file is licensed under the MIT X11 License:
# http://www.opensource.org/licenses/mit-license.php
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME => "Test::Run",
    VERSION_FROM => "lib/Test/Run/Core.pm",
    PREREQ_PM =>
    {
        'Class::Accessor' => 0,
        'File::Spec' => 0.6,
        'List::Util' => 0,
        'NEXT' => 0,
        'Scalar::Util' => 0,
        'TAP::Parser' => "0.51",
        'Test::Harness' => "2.53",
        'Test::Trap' => 0,
        'Text::Sprintf::Named' => '0.02',
    },
    PL_FILES => {},
);
