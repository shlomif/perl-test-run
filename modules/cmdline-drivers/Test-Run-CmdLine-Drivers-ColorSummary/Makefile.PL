use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Test::Run::CmdLine::Drivers::ColorSummary',
    AUTHOR              => 'Shlomi Fish <shlomif@iglu.org.il>',
    VERSION_FROM        => 'lib/Test/Run/CmdLine/Drivers/ColorSummary.pm',
    ABSTRACT_FROM       => 'lib/Test/Run/CmdLine/Drivers/ColorSummary.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Test-Run-CmdLine-Drivers-ColorSummary-*' },
);
