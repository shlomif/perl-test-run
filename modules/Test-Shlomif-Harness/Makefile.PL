require 5.005_03;

use ExtUtils::MakeMaker;
use ExtUtils::Command qw( touch rm_f );

use constant FLAG_SKIP_PROVE => "t/SKIP-PROVE";

my @files = qw(
    Run/Obj.pm
);

my %parms = (
    NAME            => "Test::Run",
    VERSION_FROM    => "lib/Test/Run/Obj.pm",
    # PM              => { map { ("lib/Test/$_" => "\$(INST_LIBDIR)/$_") } @files },
    PREREQ_PM       => 
    {
        'File::Spec' => 0.6,
        'Test::Harness' => "2.53",
    },
    INSTALLDIRS     => 'perl',
    clean           => { FILES => join( " ", FLAG_SKIP_PROVE, 'Test-Harness-*', '*~' ) },
);

my $install_prove = eval "use Pod::Usage 1.12; 1";
# Added by Shlomi Fish: Don't install prove since at the moment we don't
# have anything like it and I don't want to override anything that
# Test::Harness supplies.
$install_prove = 0;
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
