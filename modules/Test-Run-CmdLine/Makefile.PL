use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Run::CmdLine',
    AUTHOR              => 'Shlomi Fish <shlomif@iglu.org.il>',
    VERSION_FROM        => 'lib/Test/Run/CmdLine.pm',
    ABSTRACT_FROM       => 'lib/Test/Run/CmdLine.pm',
    PL_FILES            => {},
    EXE_FILES => [ "bin/runprove", ],
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Run::Core' => '0.0101',
        'UNIVERSAL::require' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Run-CmdLine-*' },
);
