require 5.005_03;

use ExtUtils::MakeMaker;
use ExtUtils::Command qw( touch rm_f );

use constant FLAG_SKIP_PROVE => "t/SKIP-PROVE";

my @files = qw(
    Harness.pm
    Harness/Iterator.pm
    Harness/Assert.pm
    Harness/Point.pm
    Harness/Straps.pm
    Harness/TAP.pod
);

my %parms = (
    NAME            => "Test::Harness",
    VERSION_FROM    => "lib/Test/Harness.pm",
    PM              => { map { ("lib/Test/$_" => "\$(INST_LIBDIR)/$_") } @files },
    PREREQ_PM       => { File::Spec => 0.6 },
    INSTALLDIRS     => 'perl',
    clean           => { FILES => join( " ", FLAG_SKIP_PROVE, 'Test-Harness-*', '*~' ) },
);

my $install_prove = eval "use Pod::Usage 1.12; 1";
if ( $install_prove ) {
    $parms{EXE_FILES} = [ 'bin/prove' ];
    local @ARGV = FLAG_SKIP_PROVE;
    rm_f();
} else {
    warn "Pod::Usage 1.12 or higher not found, so prove utility will not be installed.\n";
    local @ARGV = FLAG_SKIP_PROVE;
    touch();
}

sub MY::postamble {
    return <<'MAKE_FRAG';
.PHONY: tags

tags:
	ctags -f tags --recurse --totals \
		--exclude=blib/ --exclude=t/lib \
		--exclude=.svn --exclude='*~' \
		--languages=Perl --langmap=Perl:+.t \
MAKE_FRAG
}

WriteMakefile( %parms );
