use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Task::Test::Run::AllPlugins',
    AUTHOR              => 'Shlomi Fish <shlomif@iglu.org.il>',
    VERSION_FROM        => 'lib/Task/Test/Run/AllPlugins.pm',
    ABSTRACT_FROM       => 'lib/Task/Test/Run/AllPlugins.pm',
    PL_FILES            => {},
    PREREQ_PM =>
    {
        'Test::Run::Core' => 0,
        'Test::Run::CmdLine' => 0,
        'Test::Run::CmdLine::Plugin::AlternateInterpreters' => 0,
        'Test::Run::CmdLine::Plugin::BreakOnFailure' => 0,
        'Test::Run::CmdLine::Plugin::ColorFileVerdicts' => 0,
        'Test::Run::CmdLine::Plugin::ColorSummary' => 0,
        'Test::Run::CmdLine::Plugin::TrimDisplayedFilenames' => 0,
        'Test::Run::Plugin::AlternateInterpreters' => 0,
        'Test::Run::Plugin::BreakOnFailure' => 0,
        'Test::Run::Plugin::ColorFileVerdicts' => 0,
        'Test::Run::Plugin::ColorSummary' => 0,
        'Test::Run::Plugin::TrimDisplayedFilenames' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Task-Latemp-*' },
);
